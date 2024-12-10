// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

library StringSanitizer {
    function sanitizeJSON(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        uint256 inputLength = inputBytes.length;

        // Pre-allocate maximum possible length (3x for worst case encoding)
        bytes memory output = new bytes(inputLength * 3);
        uint256 outputIndex = 0;

        bytes1 char;

        for (uint256 i = 0; i < inputLength;) {
            char = inputBytes[i];

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

            unchecked {
                ++i;
            }
        }

        // Create final bytes array of exact length needed
        bytes memory finalOutput = new bytes(outputIndex);
        for (uint256 i = 0; i < outputIndex;) {
            finalOutput[i] = output[i];
            unchecked {
                ++i;
            }
        }

        return string(finalOutput);
    }

    function sanitizeSVG(string memory input) internal pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        uint256 inputLength = inputBytes.length;

        // Pre-allocate maximum possible length (3x for worst case encoding)
        bytes memory output = new bytes(inputLength * 3);
        uint256 outputIndex = 0;

        bytes1 char;

        for (uint256 i = 0; i < inputLength;) {
            char = inputBytes[i];

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

            unchecked {
                ++i;
            }
        }

        // Create final bytes array of exact length needed
        bytes memory finalOutput = new bytes(outputIndex);
        for (uint256 i = 0; i < outputIndex;) {
            finalOutput[i] = output[i];
            unchecked {
                ++i;
            }
        }

        return string(finalOutput);
    }
}
