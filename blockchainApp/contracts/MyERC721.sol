// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// スマートコントラクトにRBACを追加する
import "@openzeppelin/contracts/access/AccessControl.sol";
// NFTにメタ情報格納先URIを返却する機能を提供する
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// 所有者毎のtokenIDを返却する機能を提供する
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MyERC721 is ERC721URIStorage, ERC721Enumerable, AccessControl {
    uint256 private _tokenIdCounter;
    // @dev このNFTを作成できる権限を表す定数
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev 継承したOpenZeppelin ERC721.solのコンストラクタが呼び出される
     * その後コントラクトをデプロイしたアカウントにMINBER＿ROLEを付与し、NFT作成ができるようにする
     * _nameはこのNFTの名前を示し、_symbolはこのNFTトークンとしてのシンボルを示す
     * 例えば、このNFTを保有している場合1<シンボル名>となることが一般的
     */
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol) {
        // NFTスマートコントラクトをデプロイしたアカウントにNFT作成を可能とするロールを付与する
        _grantRole(MINTER_ROLE, _msgSender());
        // ロール管理者のロールも付与しておく
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev このNFTを作成する関数
     * 呼び出しがされると、toに格納されたアドレスが作成されたNFTの保有者となる
     * _tokeenURIには、作成するNFTのmetadataが示されるjsonファイルのURIを格納する
     * 前提条件:
     * - _to: NFTが受け取り可能である、つまり有効なアドレスであること
     * （OpenZeppelin ERC721の実装によりチェックされる)
     */
    function safeMint(address to, string memory _tokenURI) public onlyRole(MINTER_ROLE) returns (uint256) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        return tokenId;
    }

    // 以下はオーバーライドした関数

    // NFTのmetadataを示すjsonファイルのURIを返却する。
    // オーバーライドが求められるが、今回はERC721Storageの標準実装のままとするため継承元呼び出しのみとなる
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // OpenZeppelin ERC721で提供される、NFTの作成やtransferの時に呼び出されるhook
    // ERC721Enumerableで NFT保有者毎の保有NFTのインデックスが作成される処理が表実装されているため、継承元の呼び出しのみとなる
    // Contractの外部からは呼び出しができない、内部関数となる
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
      internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // NFTをburn(焼却)するための関数でERC721URIStorageによりオーバーライドが強制される
    // 今回はNFT焼却機能は外部提供しないため、継承元の呼び出しのみとする
    // Contractの外部からは呼び出しができない、内部関数となる
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // ERC-165で定義されている、スマートコントラクトが特定のインターフェースをサポートしているかを確認するための関数
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable, ERC721URIStorage)
      returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
