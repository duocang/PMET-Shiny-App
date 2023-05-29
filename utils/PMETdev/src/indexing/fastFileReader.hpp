//  Created by Paul Brown on 11/09/2020.
//  Copyright © 2020 Paul Brown. All rights reserved.
//

#ifndef fastFileReader_hpp
#define fastFileReader_hpp

#include <algorithm>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

// class to handle reading file and returning content as one string and also returns number of lines in original file

class cFastFileReader {
public:
  long getContent(const std::string fname, std::stringstream &content);
};

#endif /* fastFileReader_hpp */
