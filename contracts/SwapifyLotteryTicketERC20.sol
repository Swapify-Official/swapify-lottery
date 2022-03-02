// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';

contract SwapifyLotteryTicketERC20 {
    using SafeMath for uint;

    string public constant name = 'Swapify Lottery Ticket Token';
    string public constant symbol = 'SWAPATICKET';
    uint8 public constant decimals = 0;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        require(value <= type(uint).max - totalSupply, "SwapifyLotteryTicketERC20: Total supply exceeded max limit.");
        totalSupply = totalSupply.add(value);
        require(value <= type(uint).max - balanceOf[to], "SwapifyLotteryTicketERC20: Balance of minter exceeded max limit.");
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        require(from != address(0), "SwapifyLotteryTicketERC20: burn from the zero address");
        require(balanceOf[from] >= value, "SwapifyLotteryTicketERC20: burn amount exceeds balance of the holder");
        balanceOf[from] = balanceOf[from].sub(value);
        require(value <= totalSupply, "SwapifyLotteryTicketERC20: Insufficient total supply.");
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        require(spender != address(0), "SwapifyLotteryTicketERC20: approve to the invalid or zero address");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        require(from != address(0), "SwapifyLotteryTicketERC20: Invalid Sender Address");
        require(to != address(0), "SwapifyLotteryTicketERC20: Invalid Recipient Address");
        require(balanceOf[from] >= value, "SwapifyLotteryTicketERC20: Transfer amount exceeds balance of sender");
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
        require(allowance[from][msg.sender] >= value, "SwapifyLotteryTicketERC20: transfer amount exceeds allowance");
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}