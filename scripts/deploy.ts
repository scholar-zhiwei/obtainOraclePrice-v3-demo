import { ethers } from "hardhat";

async function main() {
    const Oracle = await ethers.getContractFactory("ObtainUniswapV3Oracle");
    const oracle = await Oracle.deploy();

    await oracle.deployed();

    console.log("Oracle deployed to:", oracle.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
