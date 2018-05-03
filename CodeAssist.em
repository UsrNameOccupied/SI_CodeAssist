macro Tester()
{
  insert_function_header()
}

// judge a line is commented or not
macro is_comment_line(comment_prefix, line) {
  ret = True
  prefix_len = strlen(comment_prefix)
  content_len = strlen(line)

  if(prefix_len > content_len) {
    ret = False
  } else {
    index = 0

    while (index < prefix_len) {
      ch = line[index]
      if(ch != comment_prefix[index]) {
        ret = False
      }

      index = index + 1
    }
  }

  return ret
}

// comment or uncomment selected lines
macro comment_selected_lines() {
  // comment line prefix
  comment_prefix = "// "
  hwnd = GetCurrentWnd()

  start_line = GetWndSelLnFirst(hwnd)
  end_line = GetWndSelLnLast(hwnd)
  hbuf = GetCurrentBuf()

  index = start_line

    while (index <= end_line) {
      content = GetBufLine (hbuf, index)
      if(!is_comment_line(comment_prefix, content)) {
        // comment lines
        content = cat(comment_prefix, content)
      } else {
        // uncomment lines
      content = strmid(content, strlen(comment_prefix) - 1, strlen(content))
      }

      PutBufLine(hbuf, index, content)

      index = index + 1
    }
}

// insert a comment line
macro insert_comment_line() {
  // comment line pattern
  comment_line = "// "
  hbuf = GetCurrentBuf()
  current_line = GetBufLnCur(hbuf)
  InsBufLine(hbuf, current_line, comment_line)
  // set the insertion point
  SetBufIns(hbuf, current_line, strlen(comment_line))
}

// paste current file path to clipboard
macro get_curr_file_path() {
  // clear clipboard
  hbufClip = GetBufHandle("Clipboard")
    ClearBuf(hbufClip)

    // paste to clipboard
  hbuf = GetCurrentBuf()
  file_path = GetBufName(hbuf)
  AppendBufLine(hbufClip, file_path)
}

// generate file header
macro insert_file_header() {
  author_mail = "ooooops.chan\@gmail.com"
  LnFirst = 0
  hbuf = GetCurrentBuf()
  fPath = GetBufName(hbuf)

  LocalTime = GetSysTime(1)
  Year = LocalTime.Year
  Month = LocalTime.Month
  Day = LocalTime.Day
  Time = LocalTime.time

  fLen = strlen(fPath)
  len = fLen
  // get file name
  while(StrMid(fPath, len - 1, len) != "\\") {
    len = len - 1
  }

  fileName = StrMid(fPath, len, fLen)

  InsBufLine(hbuf, LnFirst++, "/**")
  InsBufLine(hbuf, LnFirst++, "  * \@file @fileName@")
  InsBufLine(hbuf, LnFirst++, "  * \@author @author_mail@")
  InsBufLine(hbuf, LnFirst++, "  * \@date @Year@-@Month@-@Day@ @Time@")
  InsBufLine(hbuf, LnFirst++, "  * \@brief write brief here.")
  InsBufLine(hbuf, LnFirst++, "  */")
  InsBufLine(hbuf, LnFirst++, "")
}

// open the directory of current file 
macro open_curr_dir() {
  buf = GetCurrentBuf();
  curFilePath = GetBufName(buf);
  cmdLine = "explorer.exe /select,@curFilePath@";

  RunCmdLine(cmdLine, Nil, 0);
}

// trim space of string head/tail
macro trim(str) {
  while(str[0] == " ") {
    str = strmid(str, 1, strlen(str))
  }

  if(strlen(str) > 1) {
    while(str[strlen(str) - 1] == " ") {
      str = strmid(str, 0, strlen(str) - 1)
    }
  }

  return str
}

// spilt type and variable name
// e.g. "const map<string, string>& map_hello_str"
macro token_parser(token_line) {
   TokenInfo = Nil
  token_line = trim(token_line)

  if(strlen(token_line) != 0) {
    len = strlen(token_line) - 1

    while(token_line[len] != " ") {
      len = len - 1
      
      if(len < 0) {
        Msg(cat("ERROR: this line don't contain white space-->>", token_line))
        return TokenInfo
      }
    }

    TokenInfo.type = strmid(token_line, 0, len)
    TokenInfo.name = strmid(token_line, len + 1, strlen(token_line))
  }

  return TokenInfo
}

// array to hold substring that spilt 
macro get_func_line_tokens(str, delim, tokens)
{
  // array, spilt function line into pieces
  token_statements = NewBuf("token_statements")

  index = 0
  delim_len = strlen(delim)
  angle_brackets_finished = True

  while(index < strlen(str)) {
    delim_index = 0

    if(str[index] == "<") {
      angle_brackets_finished = False
    } else if(str[index] == ">") {
      angle_brackets_finished = True
    }
    
    while(delim_index < delim_len) {
      if(str[index] == delim[delim_index] && angle_brackets_finished) {
        // if substring is not empty
        if(index > 0) {
          substring = strmid(str, 0, index)
          AppendBufLine(token_statements, substring)
        }

        // if have remaining
        if((index + 1) <= (strlen(str) - 1)) {
          str = strmid(str, index + 1, strlen(str))
          index = -1
          break
        } else {
          // ignore the last character
          str = ""
          break
        }
      }
      delim_index = (delim_index + 1)
    }

    index = index + 1
  }

  // if no delim found, whole string put into array
  if(strlen(str) > 0 && index == strlen(str)) {
    AppendBufLine(token_statements, str)
  }

  index = 0
  count = GetBufLineCount(token_statements)

  while(index < count) {
    content = GetBufLine(token_statements, index)
    token = token_parser(content)
    AppendBufLine(tokens, token)
    index = index + 1
  }

  CloseBuf(token_statements)

  return
}

// e.g. "int SayHello(int a, const map<string, string>& map_hello_str) { "
macro generate_function_comment()
{
  // array
  tokens = NewBuf("tokens")
  delim = ",;{}()"

  curr_file = GetCurrentBuf()
  ln = GetBufLnCur(curr_file)
  func_line = GetBufLine(curr_file, ln)

  InsBufLine(curr_file, ln, "/**")
  ln = ln + 1 
  InsBufLine(curr_file, ln, " * \@brief")

  get_func_line_tokens(func_line, delim , tokens)

  // iterate tokens
  // we assume that the first token is the function name and it's return type
  index = 1
  count = GetBufLineCount(tokens)

  while(index < count) {
    token = GetBufLine(tokens, index)

    if(token != Nil) {
      ln = ln + 1 
      InsBufLine(curr_file, ln, cat(" * \@param ", token.name))
    }

    index = index + 1
  }

  CloseBuf(tokens)

  ln = ln + 1 
  InsBufLine(curr_file, ln, " * \@warning")
  ln = ln + 1 
  InsBufLine(curr_file, ln, " * \@return")
  ln = ln + 1 
  InsBufLine(curr_file, ln, " */")
}

// string compare
macro string_compare(str1, str2) {
  if(strlen(str1) != strlen(str2)) {
    return False
  }

  index = 0

  while (index < strlen(str1)) {
    ch = str1[index]
    if(ch != str2[index]) {
      return False
    }

    index = index + 1
  }

  return True
}

// complete code while match special abbreviation
macro code_complete() {
  curr_file = GetCurrentBuf()
  ln = GetBufLnCur(curr_file)
  // get abbreviation
  abbr = GetBufLine(curr_file, ln)
  // trim blank space
  abbr = trim(abbr)

  if(string_compare(abbr, "for")) { 
    PutBufLine(curr_file, ln, " for (size_t i = 0; i < ; i++) {")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " }")
  } else if(string_compare(abbr, "do")) {
    PutBufLine(curr_file, ln, " do {")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " } while();")
  } else if(string_compare(abbr, "#ifdef")) {
    name = Ask("Please input your macro name!")

    PutBufLine(curr_file, ln, cat(" #ifdef", name))
    ln = ln + 1 
    InsBufLine(curr_file, ln, cat(" #endif", name))
  } else if(string_compare(abbr, "if")) {
    PutBufLine(curr_file, ln, " if () {")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " }")
  } else if(string_compare(abbr, "ifel")) {
    PutBufLine(curr_file, ln, " if () {")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " } else {")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " }")
  } else if(string_compare(abbr, "switch")) {
    PutBufLine(curr_file, ln, " switch () {")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " case :")
    ln = ln + 1 
    InsBufLine(curr_file, ln, "   break;")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " default:")
    ln = ln + 1 
    InsBufLine(curr_file, ln, "   break;")
    ln = ln + 1 
    InsBufLine(curr_file, ln, " }")
  } else if(string_compare(abbr, "iter")) {
    name = Ask("Please input your variable name that to be iterated!")

    statement = cat("for (", name);
    statement = cat(statement, "_it");
    statement = cat(statement, " = ");
    statement = cat(statement, name);
    statement = cat(statement, ".begin(); ");
    statement = cat(statement, name);
    statement = cat(statement, " = ");
    statement = cat(statement, name);
    statement = cat(statement, ".end(); ");
    statement = cat(statement, name);
    statement = cat(statement, "_it++");
    statement = cat(statement, ") {");

    PutBufLine(curr_file, ln, statement)
    ln = ln + 1 
    InsBufLine(curr_file, ln, "}")
  }
}

// duplicate current line
macro duplicate_curr_line() {
  curr_file = GetCurrentBuf()
  ln = GetBufLnCur(curr_file)
  // get current line
  content = GetBufLine(curr_file, ln)
  ln = ln + 1 
  InsBufLine(curr_file, ln, content)
}
