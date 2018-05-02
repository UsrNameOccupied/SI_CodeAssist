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

macro insert_function_header() {

	hbuf = GetCurrentBuf()
	declaration_line = GetBufLnCur(hbuf)
	sym_info = GetSymbolLocationFromLn(hbuf, declaration_line)

	Msg(sym_info.Symbol)
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

// open the directory of current file 
macro open_curr_dir() {
	buf = GetCurrentBuf();
	curFilePath = GetBufName(buf);
	cmdLine = "explorer.exe /select,@curFilePath@";

	RunCmdLine(cmdLine, Nil, 0);
}
