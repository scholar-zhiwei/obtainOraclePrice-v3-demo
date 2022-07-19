import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers} from "hardhat";
import {BigNumber,utils} from "ethers";
describe("oracle", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshopt in every test.

    describe("Deployment", function () {
        let owner: any;
        let oracle: any;
        before("", async function () {
            owner = (await ethers.getSigners())[0];
            const Oracle = await ethers.getContractFactory("ObtainUniswapV3Oracle");
            oracle = await Oracle.deploy();
        });
        it("Should set the right unoracleTime", async function () {
            const v3Factory = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
            const usdc = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
            const dai = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
            const [sqrtPrice, cardinality ] = await oracle.getSqrtTWAP(360000, usdc, dai, v3Factory)
            //获取的价格是：sqrtPriceX96 = sqrt(price) * 2^96 
            const math = BigNumber.from(2).pow(96); 
            //.mul(1e12)为dai和usdc的精度差 dai 1e18   usdc 1e8
            const price = (BigNumber.from(sqrtPrice).mul(1e7).div(math)).pow(2).mul(1e12); 
            console.log(price);
            console.log(cardinality);
            console.log(sqrtPrice);
        });
    });
});
