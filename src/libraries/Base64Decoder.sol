// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library Base64Decoder {
    string constant private TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    function decode(string memory data) internal pure returns (bytes memory) {
        bytes memory dataBytes = bytes(data);
        require(dataBytes.length % 4 == 0, "Invalid base64 length");
        
        uint256 paddingLength;
        if (dataBytes.length > 0) {
            if (dataBytes[dataBytes.length - 1] == 0x3D) paddingLength++;
            if (dataBytes[dataBytes.length - 2] == 0x3D) paddingLength++;
        }

        uint256 outputLength = (dataBytes.length / 4) * 3 - paddingLength;
        bytes memory output = new bytes(outputLength);
        uint256 outputPtr;

        for (uint256 i = 0; i < dataBytes.length - paddingLength; i += 4) {
            uint256 value;
            value = (_base64CharCode(dataBytes[i]) << 18) +
                   (_base64CharCode(dataBytes[i + 1]) << 12) +
                   (_base64CharCode(dataBytes[i + 2]) << 6) +
                   _base64CharCode(dataBytes[i + 3]);

            if (outputPtr < outputLength) output[outputPtr++] = bytes1(uint8(value >> 16));
            if (outputPtr < outputLength) output[outputPtr++] = bytes1(uint8(value >> 8));
            if (outputPtr < outputLength) output[outputPtr++] = bytes1(uint8(value));
        }

        return output;
    }

    function _base64CharCode(bytes1 char) private pure returns (uint256) {
        uint8 value = uint8(char);
        
        if (value >= 0x41 && value <= 0x5A) return value - 0x41;        // A-Z
        if (value >= 0x61 && value <= 0x7A) return value - 0x61 + 26;   // a-z
        if (value >= 0x30 && value <= 0x39) return value - 0x30 + 52;   // 0-9
        if (value == 0x2B) return 62;                                    // +
        if (value == 0x2F) return 63;                                    // /
        if (value == 0x3D) return 0;                                     // =
        revert("Invalid base64 character");
    }
}