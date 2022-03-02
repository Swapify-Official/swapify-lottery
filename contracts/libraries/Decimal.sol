// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './SafeMath.sol';

library Decimal {
    using SafeMath for uint;
    uint8 public constant decimals = 18;
    /**
     * @dev This method represents number of digits after decimal point supported
     */
    function multiplier() internal pure returns(uint) {
        return 10**decimals;
    }
    /**
     * @dev This method returns integer part of solidity decimal
     */
    function integer(uint _value) internal pure returns (uint) {
        return (_value / multiplier()) * multiplier(); // Can't overflow
    }
    /**
     * @dev This method returns fractional part of solidity decimal
     */
    function fractional(uint _value) internal pure returns (uint) {
        return _value.sub(integer(_value));
    }
    /**
     * @dev This method separates out solidity decimal to integral & fraction parts
     */
    function decimalFrom(uint _value) internal pure returns(uint, uint) {
        return ((_value / multiplier()), fractional(_value));
    }
    /**
     * @dev This method converts integral & fraction parts into solidity decimal
     */
    function decimalTo(uint _integral, uint _fractional) public pure returns(uint) {
        //return _integral.mul(multiplier()).add(_fractional.mul(multiplier()) / calculateFractionMultiplier(_fractional));
        return _integral.mul(multiplier()).add(_fractional);
    }

    function calculateFractionMultiplier(uint number) internal pure returns(uint) {
        uint fractionMultiplier = 1;
        while (number != 0) {
            number /= 10;
            fractionMultiplier = fractionMultiplier.mul(10);
        }
        return fractionMultiplier;
    }
    /**
     * @dev This method adds solidity decimal with integer value
     */
    function uintAddition(uint _value, uint x) internal pure returns(uint) {
        return _value.add(x.mul(multiplier()));
    }
    /**
     * @dev This method adds solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalAddition(uint _value, uint x) internal pure returns(uint) {
        return _value.add(x);
    }
    /**
     * @dev This method adds solidity decimal with integer value
     */
    function uintSubtraction(uint _value, uint x) internal pure returns(uint) {
        return _value.sub(x.mul(multiplier()));
    }
    /**
     * @dev This method adds solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalSubtraction(uint _value, uint x) internal pure returns(uint) {
        return _value.sub(x);
    }
    /**
     * @dev This method multiplies solidity decimal with integer value
     */
    function uintMultiply(uint _value, uint x) internal pure returns(uint) {
        return _value.mul(x);
    }
    /**
     * @dev This method multiplies solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalMultiply(uint _value, uint y) internal pure returns (uint) {
        if (_value == 0 || y == 0) return 0;

        // Separate into integer and fractional parts
        // x = x1 + x2, y = y1 + y2
        uint x1 = integer(_value);
        uint x2 = fractional(_value);
        uint y1 = integer(y);
        uint y2 = fractional(y);

        // (x1 + x2) * (y1 + y2) = (x1 * y1) + (x1 * y2) + (x2 * y1) + (x2 * y2)
        uint x1y1 = x1.mul(y1);
        uint x2y1 = x2.mul(y1);
        uint x1y2 = x1.mul(y2);
        uint x2y2 = x2.mul(y2);

        return (x1y1.add(x2y1).add(x1y2).add(x2y2)) / multiplier();
    }

    function reciprocal(uint x) internal pure returns (uint) {
        assert(x != 0);
        return multiplier() * multiplier() / x;
    }
    /**
     * @dev This method divides solidity decimal with solidity decimal
     * Assumption both the decimals conatains same decimal multiplier
     */
    function decimalDivide(uint _value, uint y) internal pure returns (uint) {
        assert(y != 0);
        return decimalMultiply(_value, reciprocal(y));
    }
}