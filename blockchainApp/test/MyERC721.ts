import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("MyERC721", function() {
  async function deployFixture() {
    const [owner, account1] = await ethers.getSigners();
    const MyERC721Factory = await ethers.getContractFactory("MyERC721");
    const MyERC721 = await MyERC721Factory.deploy('TestNFT', 'MYNFT');
    return { MyERC721, owner, account1 };
  }

  describe("初期流通量とNFT作成のテスト", function() {
    it("初期流通量は0", async function () {
      const { MyERC721 } = await loadFixture(deployFixture);
      expect(await MyERC721.totalSupply()).to.equal(0);
    });
    it("MyERC721を作成するテスト", async function (){
      const { MyERC721, account1 } = await loadFixture(deployFixture);
      // NOTE: Contractに関して特に明示的なconnectメソッドの呼び出しがなければ、ownerアカウントによるTx発行となる
      await MyERC721.safeMint(account1.address, 'https://example.com/nft1.json');
      // account1が所有するNFT数が一つ増えていることの確認
      expect(await MyERC721.balanceOf(account1.address)).to.equal(1);
    });
    it("account1からは作成ができないことの確認", async function() {
      const { MyERC721, account1 } = await loadFixture(deployFixture);
      // hardhat-chai-matcherの機能を使ってTxが意図したエラーでRevertされることを確認
      await expect(
        MyERC721.connect(account1).safeMint(account1.address, 'https://example.com/nft1.json')
      ).to.be.revertedWith(/AccessControl: account .* is missing role. */);
    });
  });

  // MyERC721をtransferするテスト
  describe("MyERC721をtransferするテスト", function() {
    it("MyERC721をtransferするテスト", async function () {
      const { MyERC721, owner, account1 } = await loadFixture(deployFixture);
      // account1を保有者とするNFTを作成する
      const txResp = await MyERC721.safeMint(account1.address, 'https://example.com/nft1.json');
      // transferイベントからtokenIDを特定する
      const logs = await MyERC721.queryFilter(MyERC721.filters.Transfer());
      const tokenId = logs.find( log => log.transactionHash == txResp.hash)!.args[2];
      // account1からownerへトランスファー
      await MyERC721.connect(account1).transferFrom(account1.address, owner.address, tokenId);
      expect(await MyERC721.ownerOf(tokenId)).to.equal(owner.address);
    });
    it("account1からowner保有のNFTはtransferができないことの確認", async function () {
      const { MyERC721, owner, account1 } = await loadFixture(deployFixture);
      const txResp = await MyERC721.safeMint(owner.address, 'https://example.com/nft1.json');
      const logs = await MyERC721.queryFilter(MyERC721.filters.Transfer());
      const tokenId = logs.find( log => log.transactionHash == txResp.hash)!.args[2];
      await expect(
        MyERC721.connect(account1).transferFrom(owner.address, account1.address, tokenId)
      ).to.be.revertedWith('ERC721: caller is not token owner or approved');
    });
    it("NFT保有者がapproveすればaccount1からもNFTをtransferできることの確認", async function() {
      const { MyERC721, owner, account1 } = await loadFixture(deployFixture);
      const txResp = await MyERC721.safeMint(owner.address, 'https://example.com/nft1.json');
      const logs = await MyERC721.queryFilter(MyERC721.filters.Transfer());
      const tokenId = logs.find( log => log.transactionHash == txResp.hash)!.args[2];
      await MyERC721.connect(owner).setApprovalForAll(account1.address, true);
      await MyERC721.connect(account1).transferFrom(owner.address, account1.address, tokenId);
      expect(await MyERC721.ownerOf(tokenId)).to.equal(account1.address);
    });
  });
});