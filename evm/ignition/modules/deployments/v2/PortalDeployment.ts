import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { getAddressParameter } from "../../utils/parameters";
import PortalFactoryV2 from "./PortalFactory";

/**
 * Greenfield V2 portal-only deployment for the non-aggregator chains. Deploys the
 * fresh, independent V2 PortalFactory (`create2_salt_v2`) and wires only the
 * network's LiFi diamond — there is no vault/aggregator on these chains.
 *
 * Portal-only analogue of `Core.ts` (which is the full vault+aggregator+factory
 * stack), mirroring `deployments/v1/Deployment.ts`. Run by `scripts/deploy-v2.ts`
 * on the `<env>_<network>_v2` deployment ids.
 */
export default buildModule("PortalDeployment", (m) => {
  const { portalFactory } = m.useModule(PortalFactoryV2);

  const lifiDiamondAddress = getAddressParameter("lifiDiamondAddress", "network");

  m.call(portalFactory, "updateConfig", [
    "0x0000000000000000000000000000000000000000",
    "0x0000000000000000000000000000000000000000",
    lifiDiamondAddress,
  ]);

  return { portalFactory };
});
