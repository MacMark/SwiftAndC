/*
    Based on Swift and C Playground from Mike Ash:
    https://gist.github.com/viteinfinite/7e48704566001c0e5cd7
    https://vimeo.com/107707576
*/

import UIKit


func malloctest() -> UnsafeMutablePointer<Void> {
    return malloc(42)
}

/*

__TF8testing510malloctestFT_GVSs20UnsafeMutablePointerT__:
pushq   %rbp
movq    %rsp, %rbp
movl    $42, %edi
popq    %rbp
jmp     _malloc


*/

func mallocfree() {
    let ptr = malloc(42)
    free(ptr)
}
mallocfree()

func mallocarray() {
    let ptr = UnsafeMutablePointer<Int8>(malloc(42))
    ptr[0] = 99
    ptr[0]
    free(ptr)
}
mallocarray()

func realloctest() {
    var ptr = UnsafeMutablePointer<Int8>(malloc(42))
    ptr[0] = 99
    ptr = UnsafeMutablePointer<Int8>(realloc(ptr, 88))
    ptr[0] // 99
    free(ptr)
}
realloctest()

func hostname() {
    var buffer = [Int8](count: 1024, repeatedValue: 0)
    gethostname(&buffer, Int(buffer.count - 1))
    puts(buffer)
}
hostname()

func memcpytest() {
    var val = 42
    var buf = [Int8](count: sizeofValue(val), repeatedValue: 0)
    memcpy(&buf, &val, Int(buf.count))
    buf
}
memcpytest()

func mmaptest() {
    let ptr = UnsafeMutablePointer<Int>(mmap(nil, Int(getpagesize()), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0))
    ptr[0] = 3
    ptr[0] // 3
    munmap(ptr, Int(getpagesize()))
}
mmaptest()

func mmapfile() {
    let file = fopen("mmapfile", "w")
    let count = Int(getpagesize()) / sizeof(Int)
    let array = Array(0..<count)
    fwrite(array, Int(getpagesize()), 1, file)
    fclose(file)
    
    let fd = open("mmapfile", O_RDWR)
    let ptr = UnsafeMutablePointer<Int>(mmap(nil, Int(getpagesize()), PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_FILE, fd, 0))
    ptr[42] // 42
    munmap(ptr, Int(getpagesize()))
}
mmapfile()

func endian() {
    let value = 42
    let bigEndian = value.bigEndian
    let value2 = Int(bigEndian: bigEndian)
    value2
}
endian()

func array() {
    let array: [Int8] = [ 65, 66, 67, 0 ]
    puts(array)
    array.withUnsafeBufferPointer { (ptr: UnsafeBufferPointer<Int8>) in
        puts(ptr.baseAddress + 1)
    }
}
array()

func files() {
    let file = fopen("foo.txt", "w")
    fwrite("hello", 5, 1, file)
    fclose(file)
    
    let file2 = fopen("foo.txt", "r")
    var array = [Int8](count: 6, repeatedValue: 0)
    fread(&array, 5, 1, file2)
    fclose(file2)
    
    puts(array)
}
files()

func writeall(fd: Int32, data: [UInt8]) {
    data.withUnsafeBufferPointer {
        (bufferPointer: UnsafeBufferPointer<UInt8>) -> Void in
        var cursor: Int = 0
        
        while cursor < bufferPointer.count {
            let toWrite = bufferPointer.count - cursor
            let written = write(fd, bufferPointer.baseAddress + cursor, Int(toWrite))
            if written < 0 && errno != EAGAIN && errno != EINTR {
                perror("write")
                abort()
            }
            cursor += written
        }
    }
}

func readsome(fd: Int32) -> [Int8]? {
    var buf = [Int8](count: 128, repeatedValue: 0)
    let result = read(fd, &buf, Int(buf.count))
    if result > 0 {
        return Array(buf[0..<result])
    } else if result == 0 {
        return nil
    } else if errno != EAGAIN && errno != EINTR {
        perror("read")
        abort()
    } else {
        return []
    }
}

func sockets() {
    let name = "mikeash.com"
    let port = "80"
    var hints = addrinfo(
        ai_flags: 0,
        ai_family: 0,
        ai_socktype: 0,
        ai_protocol: IPPROTO_TCP,
        ai_addrlen: 0,
        ai_canonname: nil,
        ai_addr: nil,
        ai_next: nil)
    
    var infoPtr: UnsafeMutablePointer<addrinfo> = nil
    getaddrinfo(name, port, &hints, &infoPtr)
    let info = infoPtr.memory
    info.ai_addr
    
    let s = socket(info.ai_family, info.ai_socktype, info.ai_protocol)
    connect(s, info.ai_addr, info.ai_addrlen)
    freeaddrinfo(infoPtr)
    
    let str = "GET / HTTP/1.0\r\nHost: mikeash.com\r\n\r\n"
    writeall(s, data: Array(str.utf8))
    
    while let buf = readsome(s) {
        print(String.fromCString(buf + [0])!)
    }
    
    close(s)
}
sockets()

func casting() {
    var x = 1.0
    withUnsafePointer(&x, {
        (ptr: UnsafePointer<Double>) -> Void in
        UnsafePointer<UInt64>(ptr).memory
        // 4,607,182,418,800,017,408
        
        let bytePtr = UnsafePointer<UInt8>(ptr)
        let bytes = (0..<sizeofValue(x)).map() { bytePtr[$0] }
        bytes
        // [0, 0, 0, 0, 0, 0, 240, 63]
    })
}
casting()

func makeCFArray() {
    var callbacks = kCFTypeArrayCallBacks
    let x = CFArrayCreateMutable(nil, 0, &callbacks)
    let str = NSString(string: "abc")
    CFArrayAppendValue(x, unsafeBitCast(str, UnsafePointer<Void>.self))
    unsafeBitCast(x, NSArray.self)
}
makeCFArray()

func varlet() {
//    let file = fopen("varlet", "w")
//    let value = 42
//    fwrite(&value, UInt(sizeofValue(value)), 1, file)
//    fclose(file)

    let file = fopen("varlet", "w")
    var value = 42
    fwrite(&value, Int(sizeofValue(value)), 1, file)
    fclose(file)
}
varlet()

func errnotest() {
    close(-1)
    errno // 9
    String.fromCString(strerror(errno))!
    // "Bad file descriptor"
}
errnotest()

















