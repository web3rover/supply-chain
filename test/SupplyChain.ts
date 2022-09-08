import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SupplyChain", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployAndInitialize() {
    // Contracts are deployed using the first signer/account by default
    const [owner, warehouseManager, customer] = await ethers.getSigners();

    const SupplyChain = await ethers.getContractFactory("SupplyChain");
    const supplyChain = await SupplyChain.deploy();
    await supplyChain.initialize();

    await supplyChain.grantRole(
      await supplyChain.WAREHOUSE_MANAGER_ROLE(),
      warehouseManager.address
    )

    const price = ethers.utils.parseUnits("0.05", "ether");
    await supplyChain.setPrice(price);

    return { supplyChain, owner, warehouseManager, customer };
  }

  async function setupInventory() {
    const { supplyChain, owner, warehouseManager, customer } = await loadFixture(deployAndInitialize);
    await supplyChain.connect(warehouseManager).addStock(100);

    return { supplyChain, owner, warehouseManager, customer };
  }

  describe("Inventory Management", async function () {
    it("Feature: Warehouse manager can add stock to the inventory", async function () {
      const { supplyChain, owner, warehouseManager } = await loadFixture(deployAndInitialize);

      await supplyChain.connect(warehouseManager).addStock(100);
      expect(await supplyChain.totalSupply()).to.equal(100);
    });

    it("Feature: Customer can NOT alter stock in inventory", async function () {
      const { supplyChain, owner, warehouseManager, customer } = await loadFixture(deployAndInitialize);
      expect(supplyChain.connect(customer).addStock(100)).reverted;
    });
  })

  describe("Customer Purchase", async function () {
    it("Feature: Customer can place an order", async function () {
      const { supplyChain, owner, warehouseManager, customer } = await loadFixture(setupInventory);

      const price = await supplyChain.price();

      const quantity = 10;
      await supplyChain.connect(customer).purchase(quantity, {
        value: price.mul(quantity)
      });

      expect((await supplyChain.orders(0)).customer).equal(customer.address)
      expect((await supplyChain.orders(0)).status).equal(0)
    });

    it("Feature: Customer cannot place an order", async function () {
      const { supplyChain, owner, warehouseManager, customer } = await loadFixture(setupInventory);

      const price = await supplyChain.price();

      const quantity = 1000;
      expect(supplyChain.connect(customer).purchase(quantity, {
        value: price.mul(quantity)
      })).reverted;
    });

    it("Feature: Warehouse manager can ship a customer order.", async function () {
      const { supplyChain, owner, warehouseManager, customer } = await loadFixture(setupInventory);

      const price = await supplyChain.price();

      const quantity = 10;
      await supplyChain.connect(customer).purchase(quantity, {
        value: price.mul(quantity)
      });

      await supplyChain.connect(warehouseManager).ship(0);
      expect((await supplyChain.orders(0)).status).equal(1);
    });
  })
});
