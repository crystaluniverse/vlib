module testdata

// file_func0 is the first function of file
fn file_func0() {}

// file_func1 is the second function of file
// - name: a name that the function will do nothing with
pub fn file_func1(name string) {}

// FileStruct0 defines the configuration params of file_func2
@[params]
pub struct FileStruct0 {
	param1 string //
	param2 int    //
}

// file_func2 is the third function of the file
// - config: configuration for file_func2
pub fn file_func2(config FileStruct0) {}

pub struct FileStruct1 {}

// file_func3 is the fourth function of the file
// is does something with param1 and param2 and creates FileStruct1
// returns the created filestruct1, a FileStruc1 struct filled in with params 1 and 2
pub fn file_func3(param1 string, param2 int) FileStruct1 {
	return FileStruc1{
		firstname: firstname
		lastname:  lastname
	}
}
