//SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./interface/ITieredPresaleFactory.sol";
import "./TieredPresale.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

error TPFactory__InvalidCreationFee();
error TPLock__OnlyPresale();

contract Factory is ITieredPresaleFactory, Ownable {
    mapping(address => bool) public isPresale;
    address[] public presales;
    uint256 public creationFee = 0.4 ether;
    uint256 public platformSellFee = 1;
    uint256 public platformReceiveFee = 2;

    //-------------------------------------------------------------------
    // Events
    //-------------------------------------------------------------------
    event ChangeCreationFee(uint256 newFee);
    event PresaleCreated(address presale, address owner, address tokenToSell);

    constructor() Ownable(msg.sender) {}

    function createPresale(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo,
        address sellToken,
        address receiveToken,
        address router,
        uint liquidityAmount
    ) external payable returns (address) {
        address[] memory addressConfig = new address[](4);
        addressConfig[0] = sellToken;
        addressConfig[1] = receiveToken;
        addressConfig[2] = msg.sender;
        addressConfig[3] = router;

        uint[] memory platformConfig = new uint[](3);
        platformConfig[0] = platformReceiveFee;
        platformConfig[1] = platformSellFee;
        platformConfig[2] = liquidityAmount;
        // Make sure to get the creation fee from the user
        // Creation fee is in NATIVE
        if (msg.value != creationFee) revert TPFactory__InvalidCreationFee();
        TieredPresale presale = new TieredPresale(
            gridInfo,
            layerCreateInfo,
            addressConfig,
            platformConfig
        );
        presales.push(address(presale));
        isPresale[address(presale)] = true;

        emit PresaleCreated(address(presale), msg.sender, addressConfig[0]);

        return address(presale);
    }

    function changeCreationFee(uint256 _newFee) external onlyOwner {
        creationFee = _newFee;
        emit ChangeCreationFee(_newFee);
    }

    function setReceiveFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 20, "Fee too high");
        platformReceiveFee = _newFee;
    }

    function setSellFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 20, "Fee too high");
        platformSellFee = _newFee;
    }

    function _safeTokenTransfer(
        address token,
        address to,
        uint256 amount
    ) private {
        (bool succ, ) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );
        if (!succ) revert TPresale__CouldNotTransfer(token, amount);
    }

    function claimTokens(address _token, address _to) external onlyOwner {
        if (_token == address(0)) {
            (bool succ, ) = _to.call{value: address(this).balance}("");
            require(succ, "Failed to send Ether");
            return;
        }
        _safeTokenTransfer(
            _token,
            _to,
            IERC20(_token).balanceOf(address(this))
        );
    }

    //-------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------
    // ONLY FOR UI and to not to be used in smart contracts
    //-------------------------------------------------------------------
    //-------------------------------------------------------------------
    function getInProgress() external view returns (address[] memory) {
        uint allPresales = presales.length;
        uint inProgress = 0;
        uint ipOffset = 0;
        for (uint i = 0; i < allPresales; i++) {
            if (
                TieredPresale(presales[i]).status() ==
                ITieredPresale.Status.IN_PROGRESS
            ) {
                inProgress++;
            }
        }
        address[] memory inProgressPresales = new address[](inProgress);
        for (uint i = 0; i < allPresales; i++) {
            if (
                TieredPresale(presales[i]).status() ==
                ITieredPresale.Status.IN_PROGRESS
            ) {
                inProgressPresales[ipOffset] = presales[i];
                ipOffset++;
            }
        }
        return inProgressPresales;
    }

    function getCompleted() external view returns (address[] memory) {
        uint allPresales = presales.length;
        uint completed = 0;
        uint offset = 0;
        for (uint i = 0; i < allPresales; i++) {
            if (
                TieredPresale(presales[i]).status() ==
                ITieredPresale.Status.FINALIZED
            ) {
                completed++;
            }
        }
        address[] memory completedPresales = new address[](completed);
        for (uint i = 0; i < allPresales; i++) {
            if (
                TieredPresale(presales[i]).status() ==
                ITieredPresale.Status.FINALIZED
            ) {
                completedPresales[offset] = presales[i];
                offset++;
            }
        }
        return completedPresales;
    }

    function getAll() external view returns (address[] memory) {
        return presales;
    }
}
