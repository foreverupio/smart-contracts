// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract ERC721RolesNoMaxSupply is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    string public constant VERSION = "1.0.0";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Timestamp when the minting process can start
    /// @dev Defined as unix timestamp in seconds
    uint256 public mintStartTime;
    /// @notice Duration during which the minting process is active after the start period
    /// @dev Defined as unix timestamp in seconds
    uint256 public mintDuration;
    /// @notice Counter to keep track of the total number of tokens minted
    uint256 private tokenIdCounter;

    /*//////////////////////////////////////////////////////////////////////////
                                    ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the minting period has ended
    error MintPeriodEnded();

    /*//////////////////////////////////////////////////////////////////////////
                            UPGRADEABLE RELATED FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _mintDuration,
        uint256 _mintStartTime
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        mintDuration = _mintDuration;
        mintStartTime = _mintStartTime;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /*//////////////////////////////////////////////////////////////////////////
                            CONTRACT-SPECIFIC FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Mint a ERC721 token to the recipient address
    /// @dev The `_tokenURI` must be generated off-chain depending on the token's rarity
    /// @param _to The recipient address to which the token will be minted
    /// @param _tokenURI The hash of the token's metadata
    function safeMint(address _to, string memory _tokenURI) public onlyRole(MINTER_ROLE) {
        // check to see if the mint process is active
        if(!getRemainingMintTime()) revert MintPeriodEnded();

        // since there will never be a number of assets greater than 2^256-1,
        // therefore `tokenIdCounter` won't overflow or underflow
        // we can increment it inside an unchecked block reducing the gas consumed
        unchecked {
            tokenIdCounter += 1;
        }
        // mint a new token to the recipient address
        _safeMint(_to, tokenIdCounter);
        // set the according tokenURI to the freshly minted token
        _setTokenURI(tokenIdCounter, _tokenURI);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Computes the remaining period of the minting time
    /// @dev Add the duration of the minting process to the starting period and substract the block timestamp
    /// @return mintRemainingTime The remaining time as unix timestamp in seconds 
    function getRemainingMintTime() internal return (uint256 mintRemainingTime) {
        return (mintStartTime + mintDuration) - block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            REQUIRED OVERRIDDEN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
