//  Created by Paul Brown on 11/09/2020.
//  Copyright © 2020 Paul Brown. All rights reserved.
//

#include "fastFileReader.hpp"

long cFastFileReader::getContent(const std::string filename, std::stringstream &content) {
  // fast way to read a text file into memory
  // reads entire file into results and returns number of lines

  long flength;
  long numLines = 0;
  bool success = false;

  std::ifstream ifs(filename, std::ifstream::binary);

  if (!ifs) {
    std::cout << "Error: Cannot open file " << filename << std::endl;
    exit(1);
  }

  ifs.seekg(0, ifs.end);
  flength = ifs.tellg();
  ifs.seekg(0, ifs.beg);

  std::string buffer(flength, '\0');

  if (!ifs.read(&buffer[0], flength))
    std::cout << "Error reading file " << filename << std::endl;
  else {
    content.str(buffer);
    success = true;
  }

  ifs.close();

  if (success) {
    // count number of lines read
    numLines = std::count(std::istreambuf_iterator<char>(content), std::istreambuf_iterator<char>(), '\n');
    // in case no \n on last line
    content.unget();
    if (content.get() != '\n')
      numLines++;
    // reset iterator
    content.seekg(0);
  } else
    exit(1);

  return numLines;
}
