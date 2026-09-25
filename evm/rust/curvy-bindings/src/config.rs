use alloy::{
    contract::RawCallBuilder,
    network::TransactionBuilder,
    primitives::{Address, Bytes, U256},
    rpc::types::TransactionRequest,
    sol_types::{SolCall, SolEvent, SolValue},
};
use anyhow::{Context, ensure};
use serde::{Deserialize, Serialize};
use serde_with::{DisplayFromStr, serde_as};
use tracing::debug;

use crate::{
    constants::*,
    curvy_aggregation_verifier::CurvyAggregationVerifier::{
        self, CurvyAggregationVerifierInstance,
    },
    curvy_aggregator_alpha_v2::{
        CurvyAggregatorAlphaV2::{self, CurvyAggregatorAlphaV2Instance},
        CurvyTypes as AggregatorTypes,
    },
    curvy_pending_notes_commitment_verifier::CurvyPendingNotesCommitmentVerifier::{
        self, CurvyPendingNotesCommitmentVerifierInstance,
    },
    curvy_vault_v2::{
        CurvyTypes as VaultTypes,
        CurvyVaultV2::{self, CurvyVaultV2Instance},
    },
    curvy_withdrawal_verifier::CurvyWithdrawalVerifier::{self, CurvyWithdrawalVerifierInstance},
    erc20_mock::ERC20Mock::{self, ERC20MockInstance},
    erc1967_proxy::ERC1967Proxy,
    multicall3::Multicall3::{self, Multicall3Instance},
    portal_factory::PortalFactory::{self, PortalFactoryInstance},
    poseidon_t4::PoseidonT4::{self, PoseidonT4Instance},
};

/// Minimal CreateX ABI; the full ABI contains an ambiguous overloaded event.
mod createx {
    alloy::sol! {
        #[allow(missing_docs)]
        event ContractCreation(address indexed newContract, bytes32 indexed salt);
        #[allow(missing_docs)]
        function deployCreate2(bytes32 salt, bytes initCode) external payable returns (address newContract);
    }
}

/// Holds addresses of all smart contracts.
#[serde_as]
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize, Default)]
pub struct CurvyContractAddresses {
    /// CreateX factory (canonical keyless-deployment address)
    #[serde_as(as = "DisplayFromStr")]
    pub createx: Address,
    /// PoseidonT4 library (linked into the aggregator implementation)
    #[serde_as(as = "DisplayFromStr")]
    pub poseidon_t4: Address,
    /// Aggregator implementation (UUPS)
    #[serde_as(as = "DisplayFromStr")]
    pub aggregator_impl: Address,
    /// Aggregator ERC1967 proxy — the address consumers talk to
    #[serde_as(as = "DisplayFromStr")]
    pub aggregator_proxy: Address,
    /// Groth16 aggregation verifier (2,3,30)
    #[serde_as(as = "DisplayFromStr")]
    pub aggregation_verifier: Address,
    /// Groth16 pending-notes-commitment verifier (5,30)
    #[serde_as(as = "DisplayFromStr")]
    pub pending_notes_commitment_verifier: Address,
    /// Groth16 withdrawal verifier (2,30)
    #[serde_as(as = "DisplayFromStr")]
    pub withdrawal_verifier: Address,
    /// Vault implementation (UUPS)
    #[serde_as(as = "DisplayFromStr")]
    pub vault_impl: Address,
    /// Vault ERC1967 proxy — the address consumers talk to
    #[serde_as(as = "DisplayFromStr")]
    pub vault_proxy: Address,
    /// PortalFactory (deterministic CreateX deployCreate2 deploy)
    #[serde_as(as = "DisplayFromStr")]
    pub portal_factory: Address,
    /// Multicall3 devenv utility
    #[serde_as(as = "DisplayFromStr")]
    pub multicall3: Address,
    /// Mock ERC20 devenv utility (`mockMint`)
    #[serde_as(as = "DisplayFromStr")]
    pub erc20_mock: Address,
}

impl IntoIterator for &CurvyContractAddresses {
    type IntoIter = std::vec::IntoIter<Address>;
    type Item = Address;

    fn into_iter(self) -> Self::IntoIter {
        vec![
            self.createx,
            self.poseidon_t4,
            self.aggregator_impl,
            self.aggregator_proxy,
            self.aggregation_verifier,
            self.pending_notes_commitment_verifier,
            self.withdrawal_verifier,
            self.vault_impl,
            self.vault_proxy,
            self.portal_factory,
            self.multicall3,
            self.erc20_mock,
        ]
        .into_iter()
    }
}

impl CurvyContractAddresses {
    /// Returns the stable Ignition-compatible address map used by Curvy clients.
    pub fn to_ignition_json(&self) -> serde_json::Value {
        let cs = |a: &Address| a.to_checksum(None);
        serde_json::json!({
            "PortalFactoryV2#CreateX": cs(&self.createx),
            "CurvyAggregator#PoseidonT4": cs(&self.poseidon_t4),
            "CurvyAggregator#CurvyAggregatorV2Implementation": cs(&self.aggregator_impl),
            "CurvyAggregator#ERC1967Proxy": cs(&self.aggregator_proxy),
            "CurvyAggregator#CurvyAggregatorAlphaV2": cs(&self.aggregator_proxy),
            "CurvyAggregator#CurvyAggregationVerifier": cs(&self.aggregation_verifier),
            "CurvyAggregator#CurvyPendingNotesCommitmentVerifier": cs(&self.pending_notes_commitment_verifier),
            "CurvyAggregator#CurvyWithdrawalVerifier": cs(&self.withdrawal_verifier),
            "CurvyVault#CurvyVaultV2Implementation": cs(&self.vault_impl),
            "CurvyVault#ERC1967Proxy": cs(&self.vault_proxy),
            "CurvyVault#CurvyVaultV2": cs(&self.vault_proxy),
            "PortalFactoryV2#PortalFactory": cs(&self.portal_factory),
            "Devenv#Multicall3": cs(&self.multicall3),
            "Devenv#ERC20Mock": cs(&self.erc20_mock),
        })
    }
}

/// Curvy contract instances. `aggregator` and `vault` point to their proxies.
#[derive(Debug, Clone)]
pub struct CurvyContractInstances<P> {
    pub aggregator: CurvyAggregatorAlphaV2Instance<P>,
    pub vault: CurvyVaultV2Instance<P>,
    pub portal_factory: PortalFactoryInstance<P>,
    pub aggregation_verifier: CurvyAggregationVerifierInstance<P>,
    pub pending_notes_commitment_verifier: CurvyPendingNotesCommitmentVerifierInstance<P>,
    pub withdrawal_verifier: CurvyWithdrawalVerifierInstance<P>,
    pub aggregator_implementation: CurvyAggregatorAlphaV2Instance<P>,
    pub vault_implementation: CurvyVaultV2Instance<P>,
    pub poseidon_t4: PoseidonT4Instance<P>,
    pub multicall3: Multicall3Instance<P>,
    pub erc20_mock: ERC20MockInstance<P>,
}

impl<P> CurvyContractInstances<P>
where
    P: alloy::providers::Provider + Clone,
{
    pub fn new(contract_addresses: &CurvyContractAddresses, provider: P) -> Self {
        Self {
            aggregator: CurvyAggregatorAlphaV2Instance::new(
                contract_addresses.aggregator_proxy,
                provider.clone(),
            ),
            vault: CurvyVaultV2Instance::new(contract_addresses.vault_proxy, provider.clone()),
            portal_factory: PortalFactoryInstance::new(
                contract_addresses.portal_factory,
                provider.clone(),
            ),
            aggregation_verifier: CurvyAggregationVerifierInstance::new(
                contract_addresses.aggregation_verifier,
                provider.clone(),
            ),
            pending_notes_commitment_verifier: CurvyPendingNotesCommitmentVerifierInstance::new(
                contract_addresses.pending_notes_commitment_verifier,
                provider.clone(),
            ),
            withdrawal_verifier: CurvyWithdrawalVerifierInstance::new(
                contract_addresses.withdrawal_verifier,
                provider.clone(),
            ),
            aggregator_implementation: CurvyAggregatorAlphaV2Instance::new(
                contract_addresses.aggregator_impl,
                provider.clone(),
            ),
            vault_implementation: CurvyVaultV2Instance::new(
                contract_addresses.vault_impl,
                provider.clone(),
            ),
            poseidon_t4: PoseidonT4Instance::new(contract_addresses.poseidon_t4, provider.clone()),
            multicall3: Multicall3Instance::new(contract_addresses.multicall3, provider.clone()),
            erc20_mock: ERC20MockInstance::new(contract_addresses.erc20_mock, provider.clone()),
        }
    }

    /// Ensures the canonical CreateX factory is deployed. This is idempotent.
    pub async fn deploy_createx_factory(provider: P) -> anyhow::Result<()> {
        let code = provider.get_code_at(CREATEX_ADDRESS).await?;
        if code.is_empty() {
            debug!("deploying CreateX factory");
            let tx = TransactionRequest::default()
                .with_to(CREATEX_DEPLOYER)
                .with_value(ETH_VALUE_FOR_CREATEX_DEPLOYER);

            provider
                .send_transaction(tx)
                .await?
                .watch()
                .await
                .context("funding the CreateX keyless deployer")?;
            let raw = hex::decode(CREATEX_SIGNED_DEPLOYMENT_TX)
                .context("decoding the embedded CreateX deployment transaction")?;
            provider.send_raw_transaction(&raw).await?.watch().await?;

            // Only meaningful on the branch that just deployed — re-reading on the
            // already-deployed path would spend an RPC round trip to re-learn what the
            // check above just told us.
            ensure!(
                !provider.get_code_at(CREATEX_ADDRESS).await?.is_empty(),
                "CreateX factory has no code at {CREATEX_ADDRESS}"
            );
        }
        Ok(())
    }

    /// Deploys `PortalFactory` through CreateX's `deployCreate2(salt, initCode)` and
    /// returns the resulting deterministic address.
    ///
    /// Mirrors `ignition/modules/deployments/v2/PortalFactory.ts`: same CreateX, same
    /// `create2_salt_v2`, same `bytecode ++ abi.encode(owner)` init code — so a localnet
    /// lands the factory where that module would. The address comes from the
    /// `ContractCreation` event rather than being recomputed, since CreateX guards the
    /// salt by sender before hashing.
    async fn deploy_portal_factory_via_createx(
        provider: P,
        deployer_address: Address,
    ) -> anyhow::Result<Address> {
        let mut init_code = PortalFactory::BYTECODE.to_vec();
        init_code.extend_from_slice(&deployer_address.abi_encode());
        let deploy_create2 = createx::deployCreate2Call {
            salt: LOCAL_CREATE2_SALT,
            initCode: Bytes::from(init_code),
        }
        .abi_encode();

        let receipt = provider
            .send_transaction(
                TransactionRequest::default()
                    .with_to(CREATEX_ADDRESS)
                    .with_input(Bytes::from(deploy_create2)),
            )
            .await?
            .get_receipt()
            .await?;
        ensure!(
            receipt.status(),
            "CreateX PortalFactory deployment reverted"
        );

        receipt
            .logs()
            .iter()
            .find(|log| {
                log.inner.address == CREATEX_ADDRESS
                    && log.topic0() == Some(&createx::ContractCreation::SIGNATURE_HASH)
            })
            .and_then(|log| log.topics().get(1).copied())
            .map(Address::from_word)
            .context("CreateX receipt is missing the PortalFactory ContractCreation event")
    }

    /// Deploys the local suite in dependency order.
    async fn inner_deploy_full_suite_for_testing(
        provider: P,
        deployer_address: Address,
    ) -> anyhow::Result<Self> {
        // Pre-deploy the CreateX factory (needed for the deterministic PortalFactory)
        CurvyContractInstances::deploy_createx_factory(provider.clone()).await?;

        debug!("deploying Curvy contracts");

        // 1. Aggregator module: PoseidonT4 → implementation (linked) → proxy →
        //    3 verifiers → verifier registration
        let poseidon_t4 = PoseidonT4::deploy(provider.clone()).await?;

        // The generated aggregator has one PoseidonT4 link slot.
        let unlinked = *CURVY_AGGREGATOR_ALPHA_V2_UNLINKED_BYTECODE;
        let placeholder = *POSEIDON_T4_LINK_PLACEHOLDER;
        ensure!(
            unlinked.matches(placeholder).count() == 1,
            "aggregator artifact must contain exactly one PoseidonT4 link placeholder"
        );
        let linked = unlinked.replace(placeholder, &hex::encode(poseidon_t4.address().as_slice()));
        ensure!(
            !linked.contains("__$"),
            "aggregator artifact contains unresolved link placeholders"
        );
        let linked_code = hex::decode(&linked).context("decoding linked aggregator bytecode")?;
        let aggregator_implementation_address =
            RawCallBuilder::new_raw_deploy(provider.clone(), linked_code.into())
                .deploy()
                .await?;
        let aggregator_implementation = CurvyAggregatorAlphaV2Instance::new(
            aggregator_implementation_address,
            provider.clone(),
        );

        let aggregator_initialize = CurvyAggregatorAlphaV2::initializeCall {
            initialOwner: deployer_address,
        }
        .abi_encode();
        let aggregator_proxy = ERC1967Proxy::deploy(
            provider.clone(),
            aggregator_implementation_address,
            aggregator_initialize.into(),
        )
        .await?;
        let aggregator =
            CurvyAggregatorAlphaV2Instance::new(*aggregator_proxy.address(), provider.clone());

        let aggregation_verifier = CurvyAggregationVerifier::deploy(provider.clone()).await?;
        let pending_notes_commitment_verifier =
            CurvyPendingNotesCommitmentVerifier::deploy(provider.clone()).await?;
        let withdrawal_verifier = CurvyWithdrawalVerifier::deploy(provider.clone()).await?;

        // Register the verifiers under their circuit dimensions (matches
        // `building-blocks/CurvyAggregator.ts`)
        aggregator
            .setPendingNotesCommitmentVerifier(
                PENDING_NOTES_COMMITMENT_BATCH_SIZE,
                *pending_notes_commitment_verifier.address(),
            )
            .send()
            .await?
            .watch()
            .await?;
        aggregator
            .setAggregationVerifier(
                AGGREGATION_MAX_INPUTS,
                AGGREGATION_MAX_OUTPUTS,
                *aggregation_verifier.address(),
            )
            .send()
            .await?
            .watch()
            .await?;
        aggregator
            .setWithdrawalVerifier(WITHDRAWAL_MAX_INPUTS, *withdrawal_verifier.address())
            .send()
            .await?
            .watch()
            .await?;

        // 2. Vault module: implementation → proxy
        let vault_implementation = CurvyVaultV2::deploy(provider.clone()).await?;
        let vault_initialize = CurvyVaultV2::initializeCall {
            initialOwner: deployer_address,
        }
        .abi_encode();
        let vault_proxy = ERC1967Proxy::deploy(
            provider.clone(),
            *vault_implementation.address(),
            vault_initialize.into(),
        )
        .await?;
        let vault = CurvyVaultV2Instance::new(*vault_proxy.address(), provider.clone());

        // 3. PortalFactory via CreateX — deterministic address (salt + owner + init code)
        let portal_factory_address =
            Self::deploy_portal_factory_via_createx(provider.clone(), deployer_address).await?;
        let portal_factory = PortalFactoryInstance::new(portal_factory_address, provider.clone());

        // 4. Devenv utilities
        let multicall3 = Multicall3::deploy(provider.clone()).await?;
        let erc20_mock = ERC20Mock::deploy(provider.clone()).await?;

        // 5. Bilateral wiring (matches `Devenv.ts` exactly)
        vault
            .setCurvyAggregatorAddress(*aggregator.address())
            .send()
            .await?
            .watch()
            .await?;
        aggregator
            .updateConfig(AggregatorTypes::AggregatorConfigurationUpdate {
                curvyVault: *vault.address(),
                portalFactory: portal_factory_address,
            })
            .send()
            .await?
            .watch()
            .await?;
        portal_factory
            .updateConfig(*vault.address(), *aggregator.address(), LOCAL_LIFI_DIAMOND)
            .send()
            .await?
            .watch()
            .await?;
        vault
            .registerToken(*erc20_mock.address())
            .send()
            .await?
            .watch()
            .await?;

        // 6. Dev-address funding (matches `Devenv.ts`): 1000 ETH + 1000 mock ERC20
        let tx = TransactionRequest::default()
            .with_to(DEV_SHIELDING_ADDRESS)
            .with_value(ETH_VALUE_FOR_DEV_SHIELDING_ADDRESS);
        provider.send_transaction(tx).await?.watch().await?;
        erc20_mock
            .mockMint(DEV_SHIELDING_ADDRESS, ERC20_VALUE_FOR_DEV_SHIELDING_ADDRESS)
            .send()
            .await?
            .watch()
            .await?;

        Ok(Self {
            aggregator,
            vault,
            portal_factory,
            aggregation_verifier,
            pending_notes_commitment_verifier,
            withdrawal_verifier,
            aggregator_implementation,
            vault_implementation,
            poseidon_t4,
            multicall3,
            erc20_mock,
        })
    }

    /// Deploys and verifies the Curvy local-development suite.
    pub async fn deploy_for_testing(
        provider: P,
        deployer_address: Address,
    ) -> anyhow::Result<Self> {
        let instances =
            Self::inner_deploy_full_suite_for_testing(provider.clone(), deployer_address).await?;

        debug!("configuring Curvy development fees");
        let gas_fees: Vec<_> = DEV_GAS_FEE_TOKEN_IDS
            .iter()
            .zip(DEV_PENDING_NOTE_COMMITMENT_FEES.iter())
            .map(|(token_id, commitment_fee)| VaultTypes::GasFees {
                tokenId: *token_id,
                portalDeployment: DEV_PORTAL_DEPLOYMENT_FEE,
                pendingNoteCommitment: *commitment_fee,
                withdrawal: DEV_WITHDRAWAL_FEE,
            })
            .collect();
        instances
            .vault
            .setPerTokenGasFees(gas_fees, DEV_COMMITMENT_GAS_FEE_ROOT)
            .send()
            .await?
            .watch()
            .await?;
        instances
            .aggregator
            .setFeeNotePublicKey(
                DEV_FEE_COLLECTOR_PUBLIC_KEY_X,
                DEV_FEE_COLLECTOR_PUBLIC_KEY_Y,
            )
            .send()
            .await?
            .watch()
            .await?;

        instances.verify(provider, deployer_address).await?;

        Ok(instances)
    }

    /// Reads the whole deployment back off-chain and fails if anything does not match
    /// what was just deployed and configured. One place answers "what does a good
    /// deployment look like".
    async fn verify(&self, provider: P, deployer_address: Address) -> anyhow::Result<()> {
        let addresses = self.get_contract_addresses();
        for address in &addresses {
            ensure!(
                address != Address::ZERO,
                "deployment returned a zero address"
            );
            ensure!(
                !provider.get_code_at(address).await?.is_empty(),
                "deployed contract has no code at {address}"
            );
        }

        ensure!(
            self.aggregator.owner().call().await? == deployer_address,
            "aggregator owner mismatch"
        );
        ensure!(
            self.vault.owner().call().await? == deployer_address,
            "vault owner mismatch"
        );
        ensure!(
            self.portal_factory.owner().call().await? == deployer_address,
            "portal factory owner mismatch"
        );
        ensure!(
            self.aggregator.curvyVault().call().await? == *self.vault.address(),
            "aggregator vault wiring mismatch"
        );
        ensure!(
            self.aggregator.portalFactory().call().await? == *self.portal_factory.address(),
            "aggregator portal factory wiring mismatch"
        );
        ensure!(
            self.aggregator
                .getPendingNotesCommitmentVerifier(PENDING_NOTES_COMMITMENT_BATCH_SIZE)
                .call()
                .await?
                == *self.pending_notes_commitment_verifier.address(),
            "pending-notes verifier registration mismatch"
        );
        ensure!(
            self.aggregator
                .getAggregationVerifier(AGGREGATION_MAX_INPUTS, AGGREGATION_MAX_OUTPUTS)
                .call()
                .await?
                == *self.aggregation_verifier.address(),
            "aggregation verifier registration mismatch"
        );
        ensure!(
            self.aggregator
                .getWithdrawalVerifier(WITHDRAWAL_MAX_INPUTS)
                .call()
                .await?
                == *self.withdrawal_verifier.address(),
            "withdrawal verifier registration mismatch"
        );
        ensure!(
            self.vault.getTokenAddress(U256::from(2)).call().await? == *self.erc20_mock.address(),
            "mock token registration mismatch"
        );

        // Dev fee configuration applied by `deploy_for_testing`.
        ensure!(
            self.aggregator.commitmentFeeRoot().call().await? == DEV_COMMITMENT_GAS_FEE_ROOT,
            "commitment fee root read-back mismatch"
        );
        let fee_key = (
            self.aggregator.feeNotePublicKey(U256::ZERO).call().await?,
            self.aggregator.feeNotePublicKey(U256::ONE).call().await?,
        );
        ensure!(
            fee_key
                == (
                    DEV_FEE_COLLECTOR_PUBLIC_KEY_X,
                    DEV_FEE_COLLECTOR_PUBLIC_KEY_Y
                ),
            "fee-note public key read-back mismatch"
        );
        for (token_id, commitment_fee) in DEV_GAS_FEE_TOKEN_IDS
            .iter()
            .zip(DEV_PENDING_NOTE_COMMITMENT_FEES.iter())
        {
            let got = self.vault.perTokenGasFees(*token_id).call().await?;
            ensure!(
                (
                    got.portalDeployment,
                    got.pendingNoteCommitment,
                    got.withdrawal
                ) == (
                    DEV_PORTAL_DEPLOYMENT_FEE,
                    *commitment_fee,
                    DEV_WITHDRAWAL_FEE
                ),
                "gas fee read-back mismatch for token {token_id}"
            );
        }
        Ok(())
    }

    pub fn get_contract_addresses(&self) -> CurvyContractAddresses {
        CurvyContractAddresses {
            createx: CREATEX_ADDRESS,
            poseidon_t4: *self.poseidon_t4.address(),
            aggregator_impl: *self.aggregator_implementation.address(),
            aggregator_proxy: *self.aggregator.address(),
            aggregation_verifier: *self.aggregation_verifier.address(),
            pending_notes_commitment_verifier: *self.pending_notes_commitment_verifier.address(),
            withdrawal_verifier: *self.withdrawal_verifier.address(),
            vault_impl: *self.vault_implementation.address(),
            vault_proxy: *self.vault.address(),
            portal_factory: *self.portal_factory.address(),
            multicall3: *self.multicall3.address(),
            erc20_mock: *self.erc20_mock.address(),
        }
    }
}

impl<P> From<&CurvyContractInstances<P>> for CurvyContractAddresses
where
    P: alloy::providers::Provider + Clone,
{
    fn from(instances: &CurvyContractInstances<P>) -> Self {
        instances.get_contract_addresses()
    }
}

#[cfg(test)]
mod tests {
    use alloy::{node_bindings::Anvil, primitives::address, providers::ProviderBuilder};

    use super::*;

    #[tokio::test]
    async fn deploy_for_testing_deploys_wires_and_initialises() {
        let anvil = Anvil::new().spawn();
        let signer: alloy::signers::local::PrivateKeySigner = anvil.keys()[0].clone().into();
        let deployer_address = signer.address();
        let provider = ProviderBuilder::new()
            .wallet(signer)
            .connect_http(anvil.endpoint_url());

        let instances = CurvyContractInstances::deploy_for_testing(provider, deployer_address)
            .await
            .expect("deploy_for_testing should succeed");

        let addresses = instances.get_contract_addresses();

        // CreateX determinism cross-check: the init code is
        // `PortalFactory::BYTECODE ++ abi.encode(owner)`, so with the anvil account-0
        // owner and LOCAL_CREATE2_SALT the factory must always land here.
        //
        // Mirrors `ignition/modules/deployments/v2/PortalFactory.ts`: same CreateX, same
        // `create2_salt_v2`, same artifact, same anvil account-0 owner. A CREATE2
        // address is a pure function of (sender, guarded salt, init code), so this
        // necessarily equals what that module produces on a localnet.
        //
        // Expect it to move whenever the init code does — a recompile that changes
        // solc's metadata is enough. Nothing hardcodes it; it flows through the
        // Ignition JSON.
        assert_eq!(
            addresses.portal_factory,
            address!("8Ae8C1aA919c6247d6D862ae6d816a364a34B60d")
        );

        // The Ignition-JSON downstream contract: exact key set, checksummed values,
        // proxy aliases pointing at the proxy address.
        let json = addresses.to_ignition_json();
        let expected_keys = [
            "PortalFactoryV2#CreateX",
            "CurvyAggregator#PoseidonT4",
            "CurvyAggregator#CurvyAggregatorV2Implementation",
            "CurvyAggregator#ERC1967Proxy",
            "CurvyAggregator#CurvyAggregatorAlphaV2",
            "CurvyAggregator#CurvyAggregationVerifier",
            "CurvyAggregator#CurvyPendingNotesCommitmentVerifier",
            "CurvyAggregator#CurvyWithdrawalVerifier",
            "CurvyVault#CurvyVaultV2Implementation",
            "CurvyVault#ERC1967Proxy",
            "CurvyVault#CurvyVaultV2",
            "PortalFactoryV2#PortalFactory",
            "Devenv#Multicall3",
            "Devenv#ERC20Mock",
        ];
        let object = json.as_object().expect("ignition json is an object");
        assert_eq!(object.len(), expected_keys.len());
        for key in expected_keys {
            assert!(object.contains_key(key), "missing ignition key {key}");
        }
        assert_eq!(
            json["CurvyAggregator#ERC1967Proxy"],
            json["CurvyAggregator#CurvyAggregatorAlphaV2"]
        );
        assert_eq!(
            json["CurvyVault#ERC1967Proxy"],
            json["CurvyVault#CurvyVaultV2"]
        );

        // `new` from addresses reconstructs the same instance set.
        let rebuilt =
            CurvyContractInstances::new(&addresses, instances.aggregator.provider().clone());
        assert_eq!(rebuilt.get_contract_addresses(), addresses);
    }
}
