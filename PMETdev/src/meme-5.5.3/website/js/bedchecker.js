//******************************************************************************
// BED format Checker
//******************************************************************************
var BedChecker = function (handler) {
  "use strict";
  // store a reference to the handler
  this.handler = handler;
  // current parsing function
  this.process = this._process_start;
  // abort flag
  this.give_up = false;
};

BedChecker.prototype._process_start = function (code, type) {
  "use strict";
  return true;
};

// When we're done, call the approprate functions on the handler
BedChecker.prototype._signal_stop = function() {
  if (typeof this.handler.progress == "function") this.handler.progress(1.0);
  if (typeof this.handler.end == "function") this.handler.end();
};

//******************************************************************************
// Public functions
//******************************************************************************

BedChecker.prototype.process_file = function (file_input, sequence_index) {
  "use strict";
  var err, me, message, comment_count, line_count, sequence_count, reader;
  me = this;
  err = false;
  comment_count = 0;
  line_count = 0;
  sequence_count = 0;
  if (this.give_up) return;
  if (typeof this.handler.begin == "function") {
    line_count = 0;
    this.handler.begin();
  }
  reader = new FileReader();
  reader.onload = function(evt) {
    "use strict";
    var enc, error;
    enc = new TextEncoder(); 
    if ((error = unusable_format(enc.encode(this.result), 400, file_input.name)) != null) {
      // report error and stop scan as we don't have a chance of understanding this file
      if (typeof me.handler.error_format == "function") 
        me.handler.error_format(error);
      me._signal_stop();
      return;
    }
    var lines = (this.result).trim().split('\n');
    line_count = lines.length;
    if (typeof me.handler.begin == "function") {
      me.handler.begin(this.size, lines.length);
    }
     for(var line = 0; line < lines.length; line++) {
        if (typeof me.handler.progress == "function") {
          me.handler.progress(line / lines.length);
        }
        if (lines[line].charAt(0) == '#') {
          comment_count++;
        }
        else {
          var tabs = lines[line].split('\t');
          if (tabs.length < 3) {
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED,
              message: "Line " + (line+1) + ": too few fields."
            };
            err = true;
            // report error and stop scan as we don't have a chance of understanding this file
            if (typeof me.handler.error_format == "function") {
              me.handler.error_format(error);
              me._signal_stop();
              return
            }
          }
          if (tabs.length > 12) {
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED, 
              message: "Line " + (line+1) + ": too many fields."
            };
            err = true;
            // report error and stop scan as we don't have a chance of understanding this file
            if (typeof me.handler.error_format == "function") {
              me.handler.error_format(error);
              me._signal_stop();
              return
            }
          }
          var chrom = tabs[0].trim();
          if (!sequence_index.has(chrom)) {
            err = true;
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED,
              message: "Line "  + (line+1) + ": sequence " + chrom + " not found in genome database."
            };
            // report error and stop scan as we don't have a chance of understanding this file
            if (typeof me.handler.error_format == "function") {
              me.handler.error_format(error);
              me._signal_stop();
              return
            }
          }
          var length = Number(sequence_index.get(chrom));
          var start = Number(tabs[1].trim());
          var stop = Number(tabs[2].trim());
            // The 2nd field thould be a positive integer
          if (isNaN(start) || (Math.floor(start) != start) || start <= 0)  {
            err = true;
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED,
              message: "Line "  + (line+1) + ": field 2 (start) is " + start + ". It must be a positive integer."
           };
           if (typeof me.handler.error_format == "function") 
              me.handler.error_format(error);
            me._signal_stop();
            return;
          }
          // The 3rd field thould be a positive integer
          if (isNaN(stop) || (Math.floor(stop)  != stop) || stop <= 0) {
            err = true;
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED,
              message: "Line "  + (line+1) + ": field 3 (stop) is " + stop + ". It must be a positive integer."
            };
            me.handler.error_format(format.type, format.name);
            me._signal_stop();
            return;
          }
          if (start > stop) {
            err = true;
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED,
              message: "Line " + (line+1) + ": field 2 (start) is " + start + ". It must be less than field 3 (stop), " + stop + "."
            };
            me.handler.error_format(error);
            me._signal_stop();
            return;
          }
          if (start > length) {
            err = true;
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED,
              message: "Line " + (line+1) + ": field 2 (start) is " + start + ". It must be less than chromosome length, " + length + "."
            };
            me.handler.error_format(error);
            me._signal_stop();
            return;
          }
          if (stop > length) {
            err = true;
            error = {
              name: "Invalid BED file", 
              type: FileType.INVALID_BED,
              message: "Line " + (line+1) + ": field 3 (end) is " + stop + ". It must be less than chromosome length, " + length + "."
            };
            me.handler.error_format(error);
            me._signal_stop();
            return;
          }
          sequence_count++;
      }
    }
    if (lines.length === 0 || comment_count === lines.length) {
            err = true;
            format = {name: "Invalid BED file", type: FileType.INVALID_BED, message: "Empty file"};
            me.handler.error_format(format.type, format.name);
            me._signal_stop();
            return;
    }
    if (comment_count === lines.length) {
            err = true;
            format = {name: "Invalid BED file", type: FileType.INVALID_BED, message: "File only contains comments"};
            me.handler.error_format(format.type, format.name);
            me._signal_stop();
            return;
    }
    me.handler.line_count = line_count;
    me.handler.comment_count = comment_count;
    me.handler.sequence_count = sequence_count;
    me._signal_stop();
  };
  if (file_input) {
    reader.readAsText(file_input);
  }
};

BedChecker.prototype.cancel = function () {
  "use strict";
  this.give_up = true;
  this.handler = {};
};

//******************************************************************************
// Bed Handler
//******************************************************************************
var BedHandler = function (options) {
  this.configure(options);
  this.reset();
};

BedHandler.prototype.configure = function (options) {
  "use strict";
  if (typeof options != "object" || options == null) options = {};
  // configure file size
  if (typeof options.file_max == "number") {
    this.max_file_size = options.file_max;
  } else {
    this.max_file_size = null; // 20 MB
  }
  // specify a maximum name length?
  if (typeof options.max_name_len == "number" && options.max_name_len >= 1) {
    this.max_name_length = options.max_name_len;
  } else {
    this.max_name_length = null;
  }
};

BedHandler.prototype.guess_alphabets = function() {
  "use strict";
  // Only DNA is currently supported for BED files.
  return [AlphStd.DNA];
};

BedHandler.prototype.reset = function () {
  // have the file details changed?
  this.updated = false;
  // the part of the file processed
  this.fraction = 0;
  // BED details
  this.file_size = 0;
  this.line_count = 0;
  this.comment_count = 0;
  this.sequence_count = 0;
  // keep track of problems found
  this.error_type = 0;
  this.error_name = null;
  this.error_message = null;
  this.encoding_error = null;
  //this.missing_name = new FileFaults();
};

BedHandler.prototype.summary = function () {
  "use strict";
  var error, warning, messages, reason, reasons, letters, add;
  var help;
  // setup
  error = false;
  warning = false;
  messages = [];
  // create closure to add messages
  add = function(is_error, message, reasons) {
    "use strict";
    messages.push({"is_error": is_error, "message": message, "reasons": reasons});
    if (is_error) error = true;
    else warning = true;
  };
  // file size warning
  if (this.max_file_size != null && this.file_size > this.max_file_size) {
    add(false, "Large file. ", ["File is " + (Math.round(this.file_size / (1<<20) )) + "MB"] + ". ")
  }
  help = " - re-save as plain text; either Unicode UTF-8 (no Byte Order Mark) or ASCII";
  if (this.error_name != null) {
    switch (this.error_type) {
      case FileType.ENCODING:
        add(true, "Bad encoding \"" + this.error_name + "\"" + help);
        break;
      case FileType.BINARY:
        add(true, "Bad format \"" + this.error_name + "\"" + help);
        break;
      case FileType.COMPRESSED:
        add(true, "Bad format \"" + this.error_name + "\" - must be decompressed first");
        break;
      case FileType.INVALID_BED:
        add(true, "Bad format \"" + this.error_name + "\" " + this.error_message);
        break;
    }
  }
  // clear updated state
  this.updated = false;
  // return state
  return {"error": error, "warning": warning, "messages": messages};
};

// tracks the progress of reading the file
BedHandler.prototype.progress = function (fraction) {
  "use strict";
  this.fraction = fraction;
};

// Reading of the file has begun
BedHandler.prototype.begin = function (num_lines, file_size) {
  "use strict";
  this.reset();
  this.line_count = num_lines;
  this.file_size = file_size;
  this.updated = true;
};

// Reading of the file has finished (perhaps early due to an error)
BedHandler.prototype.end = function () {
  "use strict";
  this.updated = true;
};

// Parsing has stopped due to an unreadable file format
BedHandler.prototype.error_format = function (error) {
  "use strict";
  this.error_type = error.type;
  this.error_name = error.name;
  this.error_message = error.message
  this.updated = true;
};

