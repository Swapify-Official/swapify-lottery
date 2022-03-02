// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Ownable.sol';
import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';

contract SwapifyRewardsERC20 is Ownable {
    using SafeMath for uint;

    string public constant name = 'Swapify Rewards Token';
    string public constant symbol = 'SWAPIFY';
    uint8 public constant decimals = 18;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev this internal function mints token to given address
     */
    function mint(address to, uint value) external onlyOwner {
        require(value <= type(uint).max - totalSupply, "SwapifyRewardsERC20: Total supply exceeded max limit.");
        totalSupply = totalSupply.add(value);
        require(value <= type(uint).max - balanceOf[to], "SwapifyRewardsERC20: Balance of minter exceeded max limit.");
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }
    /**
     * @dev this internal function burns rewards token from the given address
     */
    function burn(address from, uint value) external onlyOwner {
        require(from != address(0), "SwapifyRewardsERC20: burn from the zero address");
        require(balanceOf[from] >= value, "SwapifyRewardsERC20: burn amount exceeds balance of the holder");
        balanceOf[from] = balanceOf[from].sub(value);
        require(value <= totalSupply, "SwapifyRewardsERC20: Insufficient total supply.");
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        require(spender != address(0), "SwapifyRewardsERC20: approve to the invalid or zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(from != address(0), "SwapifyRewardsERC20: Invalid Sender Address");
        require(to != address(0), "SwapifyRewardsERC20: Invalid Recipient Address");
        require(balanceOf[from] >= value, "SwapifyRewardsERC20: Transfer amount exceeds balance of sender");
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "SwapifyRewardsERC20: transfer amount exceeds allowance");
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}