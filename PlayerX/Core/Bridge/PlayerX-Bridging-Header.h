// 桥接 native/bridge 导出的 C 符号（由 scripts/build-core-xcframework.sh 生成在
// native/build/ios/Headers/DuanjuCore.h，project.yml 里的 HEADER_SEARCH_PATHS 指向那里）。
#import "DuanjuCore.h"

// 站源密码锁的 PBKDF2-HMAC-SHA256（CommonCrypto 是系统库，不需要额外链接设置）。
#import <CommonCrypto/CommonCrypto.h>
