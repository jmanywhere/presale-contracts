//SPDX-License-Identifier: MIT
pragma solidity =0.8.23 ^0.8.0 ^0.8.20;

// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// lib/openzeppelin-contracts/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// src/interface/ITieredPresale.sol



interface ITieredPresale {
    /// @dev to change from PENDING to IN_PROGRESS, status has to check if startBlock is reached and currentLayerId == 0
    enum Status {
        PENDING, // sale is not started yet
        IN_PROGRESS, // sale is in progress
        COMPLETED, // sale is completed
        FINALIZED // sale is already finalized and tokens claimed and added for liquidity
    }
    struct LayerInfo {
        uint256 tokensToSell;
        uint256 pricePerGrid;
        uint256 startBlock;
        uint256 endBlock;
        uint256 prevRewardAmount; // rewards assigned to this layer from next layer
        uint8 liquidityBasisPoints;
        uint8 referralBasisPoints;
        uint8 previousLayerBasisPoints;
        uint8 gridsOccupied; // number of grids occupied in this layer
        uint8 prevLayerId;
    }

    struct UserLayerInfo {
        uint256 totalDeposit;
        uint256 totalTokensToClaim;
        uint256 totalReferralRewards;
        address referral;
        uint8 gridsOccupied;
        bool claimed;
    }

    function deposit(address referral) external payable;

    function claimTokensAndRewards() external;

    // ----------------------------------
    // OWNER FUNCTIONS
    // ----------------------------------
    function setLayerStartBlock(uint8 layerId, uint256 startBlock) external;

    function setLayerDuration(uint8 layerId, uint256 duration) external;

    function setLayerPricePerGrid(uint8 layerId, uint256 pricePerGrid) external;

    function setLayerLiquidityBasisPoints(
        uint8 layerId,
        uint8 liquidityBasisPoints
    ) external;

    function setLayerReferralBasisPoints(
        uint8 layerId,
        uint8 referralBasisPoints
    ) external;

    function setLayerPreviousLayerBasisPoints(
        uint8 layerId,
        uint8 previousLayerBasisPoints
    ) external;

    function finalizeSale() external;

    //----------------------------------
    // VIEW FUNCTIONS
    //----------------------------------

    function totalLayers() external view returns (uint8);

    function currentLayerId() external view returns (uint8);

    function nextLayerId() external view returns (uint8);

    function saleToken() external view returns (address);

    function receiveToken() external view returns (address);

    function saleStatus() external view returns (Status);

    function rewardsToClaim(
        uint8 layerId,
        address user
    )
        external
        view
        returns (uint256 depositClaim, uint referralTokens, uint layerTokens);

    function usersOnLayer(
        uint8 layerId
    ) external view returns (address[] memory);

    function uniqueInvestorCount() external view returns (uint256);

    function canFinalize() external view returns (bool);

    /*---------------------------------------
     *  EVENTS
     *--------------------------------------*/

    event Deposit(address indexed user, uint8 layerId);

    event ClaimTokens(
        address indexed user,
        uint saleTokenAmount,
        uint referralAmount,
        uint layerRewardAmount
    );

    event OwnerClaimRaise(uint amount);

    event LayerCompleted(uint8 indexed layerId);

    event SaleEnded(uint timestamp);

    event LayerStartBlockChanged(uint8 indexed layerId, uint256 newStartBlock);

    event LayerDurationChanged(uint8 indexed layerId, uint256 newDuration);

    event LayerPricePerGridChanged(
        uint8 indexed layerId,
        uint256 newPricePerGrid
    );

    event LayerLiquidityBasisPointsChanged(
        uint8 indexed layerId,
        uint8 newLiquidityBasisPoints
    );

    event LayerReferralBasisPointsChanged(
        uint8 indexed layerId,
        uint8 newReferralBasisPoints
    );

    event LayerPreviousLayerBasisPointsChanged(
        uint8 indexed layerId,
        uint8 newPreviousLayerBasisPoints
    );
    event TotalTokensForLiquidityChanged(uint256 newTotalTokensForLiquidity);
}

// src/interface/ITieredPresaleFactory.sol



interface ITieredPresaleFactory {
    /**
     * @dev Creates a new presale contract and registers it in the factory.
     */
    function createPresale(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo,
        address sellToken,
        address receiveToken,
        address router,
        uint liquidityAmount
    ) external payable returns (address);

    function getInProgress() external view returns (address[] memory);

    function getCompleted() external view returns (address[] memory);

    function getAll() external view returns (address[] memory);

    /*---------------------------------------
     *  EVENTS
     *--------------------------------------*/

    event CreatePresale(
        address indexed presale,
        address indexed owner,
        address indexed tokenToSell
    );
}

// src/interface/IUniswapV2.sol



interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// lib/openzeppelin-contracts/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// src/TieredPresale.sol










error TPresale__InvalidSetup();
error TPresale__InvalidCaller();
error TPresale__InProgress();
error TPresale__NotStarted();
error TPresale__CouldNotTransfer(address _token, uint amount);
error TPresale__SaleEnded();
error TPresale__SaleNotEnded();
error TPresale__CantClaim();
error TPresale__InvalidDepositAmount();
error TPresale__NotEnoughTokens();

contract TieredPresale is ITieredPresale, Ownable, ReentrancyGuard {
    //-----------------------------------------------------------------------------------
    // GLOBAL STATE
    //-----------------------------------------------------------------------------------
    mapping(uint8 layerId => LayerInfo) public layer;
    mapping(uint8 layerId => address[] users) public layerUsers;
    mapping(uint8 layerId => mapping(address user => UserLayerInfo))
        public userLayer;
    uint256 public constant BASIS_POINTS = 100;
    uint256 public totalTokensToSell;
    uint256 public receiveForLiquidity;
    uint256 public receiveForReferral;
    uint256 public receiveForPrevLayer;
    uint256 public totalTokensSold;
    uint256 public tokensForLiquidity;
    //-----------------------
    uint256 public platformFeeReceive;
    // percentage that goes to the platform in form of tokens TO SELL
    uint256 public platformFeeSell;
    //-----------------------

    address public saleToken;
    address public receiveToken;
    address public saleOwnerWallet;
    address public router;
    uint256 public uniqueInvestorCount;
    uint8 public immutable totalLayers;
    uint8 public immutable gridsPerLayer;
    uint8 private offsetLayer = 1;
    Status public status = Status.PENDING;

    //-----------------------------------------------------------------------------------
    // MODIFIERS
    //-----------------------------------------------------------------------------------
    modifier onlySaleOwner() {
        if (msg.sender != saleOwnerWallet) revert TPresale__InvalidCaller();
        _;
    }

    //-----------------------------------------------------------------------------------
    // CONSTRUCTOR
    //-----------------------------------------------------------------------------------
    /**
     * @notice CONSTRUCTOR
     * @param gridInfo Grid settings
     * [0] totalLayers
     * [1] gridSize
     * LAYER ONE
     * [2] liquidityBasisPoints
     * [3] referralBasisPoints
     * OTHER LAYERS
     * [4] liquidityBasisPoints
     * [5] referralBasisPoints
     * [6] previousLayerBasisPoints
     * @param layerCreateInfo Layer settings
     * LAYER ONE
     * [0] startBlock
     * [1] blockDuration
     * [2] pricePerGrid
     * [3] tokensPerGrid
     * OTHER LAYERS
     * [4] blockDuration
     * [5] pricePerGrid
     * [6] tokensPerGrid
     * @param addressConfig Addresses relevant for configurations
     * [0] saleToken
     * [1] receiveToken
     * [2] saleOwner
     * [3] routerToUse
     * @param platformConfig Configurations for fees and token amount used for liquidity
     * [0] platformFeeReceive
     * [1] platformFeeSell
     * [2] tokensToAddForLiquidity
     */
    constructor(
        uint8[] memory gridInfo,
        uint256[] memory layerCreateInfo,
        address[] memory addressConfig,
        uint256[] memory platformConfig
    ) Ownable(msg.sender) {
        saleToken = addressConfig[0];
        receiveToken = addressConfig[1];
        saleOwnerWallet = addressConfig[2];
        router = addressConfig[3];
        platformFeeReceive = platformConfig[0];
        platformFeeSell = platformConfig[1];
        tokensForLiquidity = platformConfig[2];
        if (
            IUniswapV2Router02(router).WETH() == address(0) ||
            gridInfo[1] > 10 ||
            gridInfo[1] < 1
        ) revert TPresale__InvalidSetup();
        totalLayers = gridInfo[0];
        gridsPerLayer = gridInfo[1] ** 2;
        // Check the Grid Info has the correct length
        uint256 configLength = gridInfo.length;

        configLength -= 4;
        if (totalLayers > 1 && configLength % 3 != 0) {
            revert TPresale__InvalidSetup();
        }
        // Check that layerCreateInfo has the correct length
        configLength = layerCreateInfo.length;
        configLength -= 4;
        if (totalLayers > 1 && configLength % 3 != 0) {
            revert TPresale__InvalidSetup();
        }

        // SETUP LAYER 1 - Layer 0 is always empty
        LayerInfo storage setupLayer = layer[1];
        uint256 totalGridsPerLayer = uint256(gridsPerLayer);
        uint tokensToSell = layerCreateInfo[3] * totalGridsPerLayer;
        uint totalTokens = tokensToSell;
        // Setup LAYER 1
        setupLayer.startBlock = layerCreateInfo[0];
        setupLayer.endBlock = layerCreateInfo[0] + layerCreateInfo[1];
        setupLayer.pricePerGrid = layerCreateInfo[2];
        setupLayer.tokensToSell = tokensToSell;
        layerUsers[1] = new address[](totalGridsPerLayer);
        setupLayer.liquidityBasisPoints = gridInfo[2];
        setupLayer.referralBasisPoints = gridInfo[3];
        setupLayer.previousLayerBasisPoints = 0;
        uint addedBasis = gridInfo[2] + gridInfo[3];
        if (addedBasis > BASIS_POINTS) revert TPresale__InvalidSetup();
        // Setup LAYER 2 and above
        for (uint8 i = 2; i <= totalLayers; i++) {
            setupLayer = layer[i];
            uint8 offset = (3 * i) - 2;
            tokensToSell = layerCreateInfo[offset + 2] * totalGridsPerLayer;
            totalTokens += tokensToSell;

            setupLayer.startBlock = layer[i - 1].endBlock;
            setupLayer.endBlock =
                setupLayer.startBlock +
                layerCreateInfo[offset];
            setupLayer.pricePerGrid = layerCreateInfo[offset + 1];
            setupLayer.tokensToSell = tokensToSell;
            layerUsers[i] = new address[](totalGridsPerLayer);
            setupLayer.liquidityBasisPoints = gridInfo[offset];
            setupLayer.referralBasisPoints = gridInfo[offset + 1];
            setupLayer.previousLayerBasisPoints = gridInfo[offset + 2];
            addedBasis =
                gridInfo[offset] +
                gridInfo[offset + 1] +
                gridInfo[offset + 2];
            if (addedBasis > BASIS_POINTS) revert TPresale__InvalidSetup();
            setupLayer.prevLayerId = i - 1;
        }
        // Factory should transfer this amount of tokens, to this contract
        totalTokensToSell = totalTokens;
    }

    //-----------------------------------------------------------------------------------
    // EXTERNAL/PUBLIC FUNCTIONS
    //-----------------------------------------------------------------------------------

    function deposit(address referral) external payable nonReentrant {
        if (
            currentLayerId() == 0 ||
            saleStatus() != Status.IN_PROGRESS ||
            canFinalize()
        ) {
            revert TPresale__SaleEnded();
        }
        // checks that the offset is shifted to the next layer
        checkForNextLayer(true);
        LayerInfo storage currentLayerInfo = layer[offsetLayer];
        // checks that layer has started
        if (currentLayerInfo.startBlock > block.number)
            revert TPresale__NotStarted();

        UserLayerInfo storage userInfo = userLayer[offsetLayer][msg.sender];

        currentLayerInfo.gridsOccupied++;
        layerUsers[offsetLayer][currentLayerInfo.gridsOccupied - 1] = msg
            .sender;
        userInfo.totalDeposit += currentLayerInfo.pricePerGrid;
        uint tokensSold = currentLayerInfo.tokensToSell / gridsPerLayer;
        totalTokensSold += tokensSold;
        userInfo.totalTokensToClaim += tokensSold;
        userInfo.gridsOccupied++;
        // Save the liquidity and referral amounts so they're not claimed by owner
        uint liquidityAmount = (currentLayerInfo.pricePerGrid *
            currentLayerInfo.liquidityBasisPoints) / BASIS_POINTS;
        receiveForLiquidity += liquidityAmount;
        spreadToReferral(offsetLayer, msg.sender, referral);

        // Set the Reward amount for the previous layer
        // only works for layer 2 and above
        if (offsetLayer > 1) {
            _spreadPrev(
                (currentLayerInfo.pricePerGrid *
                    currentLayerInfo.previousLayerBasisPoints) / BASIS_POINTS,
                offsetLayer - 1
            );
        }

        // Check that enough tokens where sent to buy a grid with native
        if (receiveToken == address(0)) {
            if (msg.value != currentLayerInfo.pricePerGrid)
                revert TPresale__InvalidDepositAmount();
        } else {
            if (msg.value > 0) revert TPresale__InvalidDepositAmount();
            _safeTokenTransferFrom(
                receiveToken,
                msg.sender,
                address(this),
                currentLayerInfo.pricePerGrid
            );
        }
        emit Deposit(msg.sender, offsetLayer);
        checkForNextLayer(false);
    }

    function claimTokensAndRewards() external nonReentrant {
        if (status != Status.FINALIZED) revert TPresale__SaleNotEnded();
        uint256 totalPrizeTokens = 0;
        uint256 totalReferralTokens = 0;
        uint256 totalLayerRewards = 0;
        for (uint8 i = 1; i <= totalLayers; i++) {
            if (userLayer[i][msg.sender].claimed) continue;
            (
                uint256 depositClaim,
                uint256 referralTokens,
                uint256 layerTokens
            ) = rewardsToClaim(i, msg.sender);
            totalPrizeTokens += depositClaim;
            totalReferralTokens += referralTokens;
            totalLayerRewards += layerTokens;
            userLayer[i][msg.sender].claimed = true;
        }
        if (
            totalPrizeTokens == 0 &&
            totalReferralTokens == 0 &&
            totalLayerRewards == 0
        ) revert TPresale__CantClaim();
        emit ClaimTokens(
            msg.sender,
            totalPrizeTokens,
            totalReferralTokens,
            totalLayerRewards
        );
        if (totalPrizeTokens > 0) {
            _safeTokenTransfer(saleToken, msg.sender, totalPrizeTokens);
        }
        uint totalReceive = totalReferralTokens + totalLayerRewards;
        if (receiveToken == address(0)) {
            (bool succ, ) = msg.sender.call{value: totalReceive}("");
            if (!succ)
                revert TPresale__CouldNotTransfer(address(0), totalReceive);
        } else {
            _safeTokenTransfer(receiveToken, msg.sender, totalReceive);
        }
    }

    function finalizeSale() external onlySaleOwner nonReentrant {
        if (!canFinalize()) revert TPresale__SaleNotEnded();
        uint256 fees = (totalTokensSold * platformFeeSell) / BASIS_POINTS;

        if (
            totalTokensSold + tokensForLiquidity + fees >
            IERC20(saleToken).balanceOf(address(this))
        ) revert TPresale__NotEnoughTokens();

        status = Status.FINALIZED;
        // Send tokens to platform
        if (fees > 0) {
            _safeTokenTransfer(saleToken, owner(), fees);
        }
        // SAFE APPROVE
        safeApprove(saleToken, router, tokensForLiquidity);
        // Send receive fees to platform
        if (receiveToken == address(0)) {
            fees = address(this).balance;
            fees -= receiveForPrevLayer + receiveForReferral;
            uint saleOwnerAmount = fees - receiveForLiquidity;
            fees = (fees * platformFeeReceive) / BASIS_POINTS;
            if (saleOwnerAmount < fees) {
                receiveForLiquidity -= fees - saleOwnerAmount;
            }
            (bool succ, ) = owner().call{value: fees}("");
            if (!succ) revert TPresale__CouldNotTransfer(address(0), fees);
            // create liquidity
            IUniswapV2Router02(router).addLiquidityETH{
                value: receiveForLiquidity
            }(
                saleToken,
                tokensForLiquidity,
                tokensForLiquidity,
                receiveForLiquidity,
                saleOwnerWallet,
                block.timestamp
            );
            uint totalReceived = address(this).balance;
            totalReceived -= receiveForPrevLayer + receiveForReferral;
            if (totalReceived > 0) {
                (succ, ) = saleOwnerWallet.call{value: totalReceived}("");
                if (!succ)
                    revert TPresale__CouldNotTransfer(
                        address(0),
                        totalReceived
                    );
            }
        } else {
            safeApprove(receiveToken, router, receiveForLiquidity);
            fees = IERC20(receiveToken).balanceOf(address(this));
            fees -= receiveForPrevLayer + receiveForReferral;

            uint saleOwnerAmount = fees - receiveForLiquidity;
            fees = (fees * platformFeeReceive) / BASIS_POINTS;
            if (saleOwnerAmount < fees) {
                receiveForLiquidity -= fees - saleOwnerAmount;
            }
            if (fees > 0) _safeTokenTransfer(receiveToken, owner(), fees);
            // create liquidity
            IUniswapV2Router02(router).addLiquidity(
                saleToken,
                receiveToken,
                tokensForLiquidity,
                receiveForLiquidity,
                tokensForLiquidity,
                receiveForLiquidity,
                saleOwnerWallet,
                block.timestamp
            );
            uint totalReceived = IERC20(receiveToken).balanceOf(address(this));
            totalReceived -= receiveForPrevLayer + receiveForReferral;
            if (totalReceived > 0)
                _safeTokenTransfer(
                    receiveToken,
                    saleOwnerWallet,
                    totalReceived
                );
        }

        // transfer rest of tokens to owner
        emit SaleEnded(block.timestamp);
    }

    function setLayerStartBlock(
        uint8 layerId,
        uint256 startBlock
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.startBlock = startBlock;
        emit LayerStartBlockChanged(layerId, startBlock);
    }

    function setLayerDuration(
        uint8 layerId,
        uint256 duration
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.endBlock = layerInfo.startBlock + duration;
        emit LayerDurationChanged(layerId, duration);
    }

    function setLayerPricePerGrid(
        uint8 layerId,
        uint256 pricePerGrid
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.pricePerGrid = pricePerGrid;
        emit LayerPricePerGridChanged(layerId, pricePerGrid);
    }

    function setLayerLiquidityBasisPoints(
        uint8 layerId,
        uint8 liquidityBasisPoints
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.liquidityBasisPoints = liquidityBasisPoints;
        emit LayerLiquidityBasisPointsChanged(layerId, liquidityBasisPoints);
    }

    function setLayerReferralBasisPoints(
        uint8 layerId,
        uint8 referralBasisPoints
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.referralBasisPoints = referralBasisPoints;
        emit LayerReferralBasisPointsChanged(layerId, referralBasisPoints);
    }

    function setLayerPreviousLayerBasisPoints(
        uint8 layerId,
        uint8 previousLayerBasisPoints
    ) external onlySaleOwner {
        LayerInfo storage layerInfo = layer[layerId];
        if (layerInfo.startBlock < block.number) revert TPresale__InProgress();
        layerInfo.previousLayerBasisPoints = previousLayerBasisPoints;
        emit LayerPreviousLayerBasisPointsChanged(
            layerId,
            previousLayerBasisPoints
        );
    }

    function setTotalTokensForLiquity(uint256 amount) external onlySaleOwner {
        tokensForLiquidity = amount;
        emit TotalTokensForLiquidityChanged(amount);
    }

    //-----------------------------------------------------------------------------------
    // INTERNAL/PRIVATE FUNCTIONS
    //-----------------------------------------------------------------------------------

    function checkForNextLayer(bool _before) private {
        uint8 currentLayer = currentLayerId();
        // dont really need to check for currentLayer == 0 since this function only gets called when currentLayer > 0
        LayerInfo storage currentLayerInfo = layer[currentLayer];
        //Advance a layer if all grids are occupied or if the endBlock is reached
        if (
            currentLayerInfo.gridsOccupied == gridsPerLayer ||
            block.number >= currentLayerInfo.endBlock
        ) {
            if (currentLayer < totalLayers) {
                emit LayerCompleted(currentLayer);
                offsetLayer++;
                currentLayerInfo = layer[offsetLayer];
                if (currentLayerInfo.endBlock <= block.number)
                    checkForNextLayer(_before);
            } else {
                if (_before) revert TPresale__SaleEnded();
                status = Status.COMPLETED;
                emit SaleEnded(block.timestamp);
            }
        }
    }

    function spreadToReferral(
        uint8 layerId,
        address user,
        address referral
    ) private {
        LayerInfo storage currentLayerInfo = layer[layerId];
        UserLayerInfo storage userInfo = userLayer[layerId][user];
        // If referral is not set, set it
        if (
            userInfo.referral == address(0) &&
            referral != address(0) &&
            referral != user
        ) {
            userInfo.referral = referral;
        }
        if (userInfo.referral == address(0)) return;
        // If referral is set, spread the referral rewards
        UserLayerInfo storage referralInfo = userLayer[layerId][referral];
        uint referralAmount = (currentLayerInfo.pricePerGrid *
            currentLayerInfo.referralBasisPoints) / BASIS_POINTS;
        referralInfo.totalReferralRewards += referralAmount;
        receiveForReferral += referralAmount;
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

    function _safeTokenTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) private {
        (bool succ, ) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                amount
            )
        );
        if (!succ) revert TPresale__CouldNotTransfer(token, amount);
    }

    function _spreadPrev(uint amount, uint8 receiveLayer) private {
        if (amount == 0) return;
        LayerInfo storage layerInfo = layer[receiveLayer];
        if (layerInfo.gridsOccupied > 0) {
            // If the layer has deposits, spread the amount to the previous layer
            if (receiveLayer > 1) {
                uint nextRoundAmount = (amount *
                    layerInfo.previousLayerBasisPoints) / BASIS_POINTS;
                amount -= nextRoundAmount;
                _spreadPrev(nextRoundAmount, receiveLayer - 1);
            }
            layerInfo.prevRewardAmount += amount;
            receiveForPrevLayer += amount;
        }
        // If the layer has no deposits, send the amount to the next layer
        else {
            if (receiveLayer > 1) _spreadPrev(amount, receiveLayer - 1);
            else receiveForPrevLayer += amount;
        }
    }

    function safeApprove(
        address _token,
        address _spender,
        uint amount
    ) private {
        (bool succ, ) = _token.call(
            abi.encodeWithSelector(IERC20.approve.selector, _spender, amount)
        );
        if (!succ) revert TPresale__CouldNotTransfer(_token, amount);
    }

    //-----------------------------------------------------------------------------------
    // EXTERNAL/PUBLIC VIEW PURE FUNCTIONS
    //-----------------------------------------------------------------------------------
    function currentLayerId() public view returns (uint8) {
        if (block.number < layer[1].startBlock) return 0;
        return offsetLayer;
    }

    function saleStatus() public view returns (Status) {
        if (status == Status.PENDING && block.number >= layer[0].startBlock) {
            return Status.IN_PROGRESS;
        }
        return status;
    }

    function usersOnLayer(
        uint8 layerId
    ) external view returns (address[] memory) {
        return layerUsers[layerId];
    }

    function rewardsToClaim(
        uint8 layerId,
        address user
    )
        public
        view
        returns (uint256 depositClaim, uint referralTokens, uint layerTokens)
    {
        UserLayerInfo storage userInfo = userLayer[layerId][user];
        LayerInfo storage layerStatus = layer[layerId];
        depositClaim = userInfo.totalTokensToClaim;
        referralTokens = userInfo.totalReferralRewards;
        if (layerStatus.gridsOccupied == 0) layerTokens = 0;
        else
            layerTokens =
                (layerStatus.prevRewardAmount * userInfo.gridsOccupied) /
                layerStatus.gridsOccupied;
    }

    function canFinalize() public view returns (bool) {
        return
            status != Status.FINALIZED &&
            (status == Status.COMPLETED ||
                block.number > layer[totalLayers].endBlock);
    }

    function nextLayerId() external view returns (uint8) {
        if (offsetLayer == totalLayers) return offsetLayer;
        return offsetLayer + 1;
    }

    function totalTokensNeededToFinalize() external view returns (uint256) {
        return
            totalTokensSold +
            tokensForLiquidity +
            ((totalTokensSold * platformFeeSell) / BASIS_POINTS);
    }
}

// src/PresaleFactory.sol








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

    receive() external payable {}

    fallback() external payable {}

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
