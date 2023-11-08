import { ethers, upgrades } from "hardhat";
import { Collection__factory, Registry, Registry__factory } from "../typechain-types";

async function main() {
  const [deployer] = await ethers.getSigners();

  // Deploy the Collection blueprint
  const collectionFactory: Collection__factory = <Collection__factory>await ethers.getContractFactory("Collection");
  const collectionContractImplementation = await upgrades.deployImplementation(collectionFactory);

  // Deploy the Registry contract
  const registryFactory: Registry__factory = <Registry__factory>await ethers.getContractFactory("Registry");
  const registryContract = await upgrades.deployProxy(
    registryFactory,
    [
      deployer.address, // default admin
      deployer.address, // upgrader
      collectionContractImplementation, // implementation
    ],
    { initializer: "initialize" }
  );
  await registryContract.waitForDeployment();

  // Information
  console.log("Collection blueprint contract deployed to: ", collectionContractImplementation);
  console.log("Registry contract deployed to: ", await registryContract.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
