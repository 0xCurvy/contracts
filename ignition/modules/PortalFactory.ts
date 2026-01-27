import {buildModule} from "@nomicfoundation/hardhat-ignition/modules";
import {getDeployedContractAddressOnNetwork, getParameter} from "./utils/deployment";

export default buildModule("PortalFactoryModule", (m) => {
    const owner = m.getAccount(0);

    const aggregatorNetwork = getParameter<string>("aggregatorNetwork", "arbitrum")
    const aggregatorChainId = getParameter<number>("aggregatorChainId", 42161);

    const curvyVaultProxyAddress = getDeployedContractAddressOnNetwork(aggregatorNetwork, "CurvyVault#ERC1967Proxy");
    const curvyAggregatorAlphaProxyAddress = getDeployedContractAddressOnNetwork(aggregatorNetwork, "CurvyAggregatorAlpha#ERC1967Proxy");

    const portalFactory = m.contract("PortalFactory", [owner, curvyVaultProxyAddress, curvyAggregatorAlphaProxyAddress, aggregatorChainId], {id: "PortalFactory"});

    // https://docs.li.fi/introduction/lifi-architecture/smart-contract-addresses
    const lifiDiamondAddress = getParameter<string>("lifiDiamondAddress");

    if(lifiDiamondAddress) {
        m.call(portalFactory, "updateLifiDiamondAddress", [lifiDiamondAddress]);
    }

    return {portalFactory};
});
