//
//  jiema.h
//  W200Demo
//
//  Created by 鱼鱼 on 16/8/25.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#ifndef jiema_h
#define jiema_h

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <MacTypes.h>

/*-------------------------------------------------------------------------
 * 函数:	audioInterface_wav2digital
 * 说明:	分析mic的adc数据，解析出数字信号
 * 参数:	x	-- 录音的数据流  输入型参数 S16 双字节有符号数据类型
 *	n	-- 数据流的长度  输入型参数 int 四字节有符号数据类型
 *	pdata   -- 解析出来的数据缓存地址指针 输出型参数 单字节无符号数据类型
 * 返回:	解析出来的数据长度 int 四字节有符号数据类型
 * ------------------------------------------------------------------------*/
int audioInterface_wav2digital(SInt16 *x, int n, unsigned char *pdata);


#endif /* jiema_h */
