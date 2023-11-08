// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Collection.sol";

contract Registry is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
  /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
  //////////////////////////////////////////////////////////////////////////*/

  string public constant VERSION = "1.0.0";
  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

  /*//////////////////////////////////////////////////////////////////////////
                                    STORAGE
  //////////////////////////////////////////////////////////////////////////*/

  address public collectionImpl;

  /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
  //////////////////////////////////////////////////////////////////////////*/

  event CreateNewCollection(address indexed owner, address indexed collectionAddress);

  /*//////////////////////////////////////////////////////////////////////////
                            UPGRADEABLE RELATED FUNCTIONS
  //////////////////////////////////////////////////////////////////////////*/

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address defaultAdmin, address upgrader, address collectionImplementation) public initializer {
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    _grantRole(UPGRADER_ROLE, upgrader);

    collectionImpl = collectionImplementation;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

  /*//////////////////////////////////////////////////////////////////////////
                            CONTRACT-SPECIFIC METHODS
  //////////////////////////////////////////////////////////////////////////*/

  function deployCollection(
    string memory _name,
    string memory _symbol,
    uint256 _mintDuration,
    uint256 _mintStartTime
  ) external returns (address) {
    ERC1967Proxy collection = new ERC1967Proxy(
      address(collectionImpl),
      abi.encodeWithSelector(Collection.initialize.selector, msg.sender, _name, _symbol, _mintDuration, _mintStartTime)
    );
    address collectionAddress = address(collection);

    emit CreateNewCollection(msg.sender, collectionAddress);
    return address(collection);
  }
}
