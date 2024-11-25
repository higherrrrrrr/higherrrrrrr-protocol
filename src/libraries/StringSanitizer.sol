// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library StringSanitizer {
    /// @notice Sanitizes string input for safe use in SVG and JSON contexts
    /// @dev Encodes special characters to prevent injection attacks
    /// @param input The raw string to sanitize
    /// @param context The context where the string will be used (1 = SVG, 2 = JSON)
    /// @return The sanitized string
    function sanitize(string memory input, uint8 context) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);

        // Pre-allocate maximum possible length (3x for worst case encoding)
        bytes memory output = new bytes(inputBytes.length * 3);
        uint256 outputIndex = 0;

        for (uint256 i = 0; i < inputBytes.length; i++) {
            bytes1 char = inputBytes[i];

            if (context == 1) {
                // SVG context
                if (char == "<") {
                    // Add "&lt;"
                    output[outputIndex++] = "&";
                    output[outputIndex++] = "l";
                    output[outputIndex++] = "t";
                    output[outputIndex++] = ";";
                } else if (char == ">") {
                    // Add "&gt;"
                    output[outputIndex++] = "&";
                    output[outputIndex++] = "g";
                    output[outputIndex++] = "t";
                    output[outputIndex++] = ";";
                } else if (char == '"') {
                    // Add "&quot;"
                    output[outputIndex++] = "&";
                    output[outputIndex++] = "q";
                    output[outputIndex++] = "u";
                    output[outputIndex++] = "o";
                    output[outputIndex++] = "t";
                    output[outputIndex++] = ";";
                } else if (char == "'") {
                    // Add "&#39;"
                    output[outputIndex++] = "&";
                    output[outputIndex++] = "#";
                    output[outputIndex++] = "3";
                    output[outputIndex++] = "9";
                    output[outputIndex++] = ";";
                } else if (char == "&") {
                    // Add "&amp;"
                    output[outputIndex++] = "&";
                    output[outputIndex++] = "a";
                    output[outputIndex++] = "m";
                    output[outputIndex++] = "p";
                    output[outputIndex++] = ";";
                } else {
                    output[outputIndex++] = char;
                }
            } else if (context == 2) {
                // JSON context
                if (char == '"') {
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = '"';
                } else if (char == "\\") {
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = "\\";
                } else if (char == "/") {
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = "/";
                } else if (uint8(char) == 0x08) {
                    // backspace
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = "b";
                } else if (uint8(char) == 0x0C) {
                    // form feed
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = "f";
                } else if (uint8(char) == 0x0A) {
                    // line feed
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = "n";
                } else if (uint8(char) == 0x0D) {
                    // carriage return
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = "r";
                } else if (uint8(char) == 0x09) {
                    // tab
                    output[outputIndex++] = "\\";
                    output[outputIndex++] = "t";
                } else {
                    output[outputIndex++] = char;
                }
            }
        }

        // Create final bytes array of exact length needed
        bytes memory finalOutput = new bytes(outputIndex);
        for (uint256 i = 0; i < outputIndex; i++) {
            finalOutput[i] = output[i];
        }

        return string(finalOutput);
    }
}
