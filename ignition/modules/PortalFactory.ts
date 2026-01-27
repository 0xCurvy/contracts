import {buildModule} from "@nomicfoundation/hardhat-ignition/modules";
import {getDeployedContractAddressOnNetwork, getParameter} from "./utils/deployment";

export default buildModule("PortalFactoryModule", (m) => {
    const owner = m.getAccount(0);

    const aggregatorNetwork = getParameter<string>("aggregatorNetwork", "arbitrum");

    const curvyVaultProxyAddress = getDeployedContractAddressOnNetwork(aggregatorNetwork, "CurvyVault#ERC1967Proxy");
    const curvyAggregatorAlphaProxyAddress = getDeployedContractAddressOnNetwork(aggregatorNetwork, "CurvyAggregatorAlpha#ERC1967Proxy");

    const portalFactory = m.contract("PortalFactory", [owner], {id: "PortalFactory"});

    // https://docs.li.fi/introduction/lifi-architecture/smart-contract-addresses
    const lifiDiamondAddress = getParameter<string>("lifiDiamondAddress", "0x0000000000000000000000000000000000000000");

    m.call(portalFactory, "updateConfig", [curvyVaultProxyAddress, curvyAggregatorAlphaProxyAddress, lifiDiamondAddress]);

    return {portalFactory};
});
