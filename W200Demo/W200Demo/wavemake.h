//
//  wavemake.h
//  W200Demo
//
//  Created by 鱼鱼 on 2016/12/21.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#ifndef wavemake_h
#define wavemake_h

#include <stdio.h>

typedef unsigned char		U8;

int bit2Pcm(U8 bit, signed short *pPcmData);
int data2Pcm(U8 *pData, int dataLen, signed short *pPcmData);
int wavemake(U8 fileBytes[], int fileBytesLen, U8 wavedata[], int wavedataLen);
#endif /* wavemake_h */
