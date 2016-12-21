//
//  wavemake.c
//  W200Demo
//
//  Created by 鱼鱼 on 2016/12/21.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#include "wavemake.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


typedef struct wave_header
{
    char			RiffID[4];		// 'R','I','F','F'	"RIFF"标志
    int				RiffSize;		// 文件长度(WAVE文件的大小, 不含前8个字节)
    char			RiffFormat[4];	// 'W','A','V','E'	"WAVE"标志
    char			FmtID[4];		// 'f','m','t',' ' "fmt "标志
    int				FmtSize;		//过渡字节(不定)16 for PCM. This is the size of the rest of the Subchunk which follows this number.
    unsigned short	FormatTag;		//格式类别, 当FormatTag=1，用的就是非压缩格式。
    unsigned short	Channels;		//通道数(单声道为1, 双声道为2)
    int				SamplesPerSec;	//采样率(每秒样本数), 表示每个通道的播放速度
    int				AvgBytesPerSec;	//波形音频数据传输速率, 其值为:通道数*每秒数据位数*每样本的数据位数/8 播放软件可以利用该值估计缓冲区大小
    unsigned short	BlockAlign;		//每样本的数据位数(按字节算), 其值为:通道数*每样本的数据位值/8， 播放软件需要一次处理多个该值大小的字节数据, 以便将其值用于缓冲区的调整
    unsigned short	BitsPerSample;	//每样本的数据位数, 表示每个声道中各个样本的数据位数. 如果有多个声道,对每个声道而言, 样本大小都一样
    char			DataID[4];		// 'd','a','t','a'
    int				DataSize;		//语音数据的长度
}tWAVE_HEADER;

#define L_R_DIFF		//左右声道反向

#if 0
#define WAVE_SAMPLE_RATE			(44100)	//采样率
#define WAVE_SAMPLE_REPEAT_CNT		44		//同一个数据重复次数，44100/(44+44)=501.137Hz
#define WAVE_SAMPLE_REPEAT_CNT1		44		//同一个数据重复次数，44100/(44+44)=501.137Hz
//#define WAVE_SAMPLE_REPEAT_CNT		5		//同一个数据重复次数，44100/(5+4)=4900Hz
//#define WAVE_SAMPLE_REPEAT_CNT1		4		//同一个数据重复次数，44100/(5+4)=4900Hz
#define WAVE_SAMPLE_REPEAT_CNT_SIGNAL	9		//uart通讯速率：44100/9=4900Hz
#else
#define WAVE_SAMPLE_RATE			(48000)	//采样率
//	#define WAVE_SAMPLE_REPEAT_CNT		48		//同一个数据重复次数，48000/(48+48)=500Hz
//	#define WAVE_SAMPLE_REPEAT_CNT1		48		//同一个数据重复次数，48000/(48+48)=500Hz
#define WAVE_SAMPLE_REPEAT_CNT		5		//同一个数据重复次数，48000/(5+5)=4800Hz
#define WAVE_SAMPLE_REPEAT_CNT1		5		//同一个数据重复次数，48000/(5+5)=4800Hz
#define WAVE_SAMPLE_REPEAT_CNT_SIGNAL	10		//uart通讯速率：48000/10=4800Hz
#endif

#define WAVE_SAMPLE_VAL_MIN			(0x8000)
#define WAVE_SAMPLE_VAL_MAX			(0x7FFF)
#define WAVE_TIME_ALL				    (1)		//秒
#define WAVE_TIME_INSERT_SIGNAL		(1)			//秒，插入通讯信号
#define WAVE_SAMPLES_PER_CH			(1024000)	//每个通道的sample数



#define COMM_WAKEUP_START_BYTE			(0x11)//(0xAA)//
/* 封包起始和结尾字节 */
#define COMM_PAKET_START_BYTE			(0x40)
#define COMM_PAKET_END_BYTE				(0x2A)

/* 收发类型 */
#define	COMM_TRANS_TYPE_SEND			(0x53)	/* 'S'---send */
#define	COMM_TRANS_TYPE_RESP			(0x52)	/* 'R'---response */

/* 命令类型 */
#define	COMM_CMD_TYPE_BARCODE			(0x01)	//条码传输
#define	COMM_CMD_TYPE_SUFFIX			(0x07)	//条码后缀设置
#define	COMM_CMD_TYPE_PREFIX			(0x08)	//条码前缀设置
#define	COMM_CMD_TYPE_RESERVE1			(0x0A)	//保留


#define	COMM_CMD_TYPE_BAT_LEV			(0x0D)	//电量获取

#define	COMM_CMD_TYPE_SCAN_MODE			(0x0E)	//扫描模式设置

#define	COMM_CMD_TYPE_RD_BAR_PRIOR		(0x10)	//读取条码解码优先级
#define	COMM_CMD_TYPE_WR_BAR_PRIOR		(0x11)	//设置条码解码优先级
#define	COMM_CMD_TYPE_RD_BAR_PARAM		(0x12)	//读取条码解码参数
#define	COMM_CMD_TYPE_WR_BAR_PARAM		(0x13)	//设置条码解码参数


#define COMM_CMD_TYPE_DEBUG_EN			(0xB0)	//debug开关
#define COMM_CMD_TYPE_DEBUG_SCAN		(0xB1)	//debug scan开关


#define	COMM_CMD_TYPE_UPDATE			(0xD0)	//软件升级

#define	COMM_CMD_TYPE_VERSION			(0xE0)	//版本信息

#define COMM_CMD_TYPE_SCAN_TRRIG		(0xEE)	//扫描触发命令


/*-------------------------------------------------------------------------
 * 函数: hsComm_send
 * 说明: 发送命令
 * 参数: transType--发送类型
 cmd--------命令id
 pData------数据buffer
 len--------数据长度
 * 返回: HY_OK------发送成功
 HY_ERROR---发送失败
 -------------------------------------------------------------------------*/
int hsComm_send(U8 transType, U8 cmd, U8 *pData, int len, U8 *cmdData, int *pCmdLen)
{
    U8 i, temp[128], sum=0;
    
    if (pData==NULL && len>0) return -1;
    
    temp[0] = COMM_PAKET_START_BYTE;
    temp[1] = len+2;
    temp[2] = transType;
    temp[3] = cmd;
    memcpy(&temp[4], pData, len);
    temp[len+5] = COMM_PAKET_END_BYTE;
    for(i=0; i<len+3; i++)
    {
        sum += temp[i+1];
    }
    temp[len+4] = sum;
    //hsComm_out_send(temp, len+6);
    memcpy(cmdData, temp, len+6);
    *pCmdLen = len+6;
    
    return 0;
}


/*
	EFM32 leuart，不论是什么频率的波形，都能产生数据，即便报frame或parity错，也有数据
	leuart只要产生了数据，不论是否有报错，必须从接收buf中读取，否则后续数据无法接收
	leuart中设置的stop bit个数，对接收无效，是发送时使用的，接收只判断一个stop bit[high]
	添加一个偶校验位[EVEN]，当发送0x55时波形为：....~~~|_|~|_|~|_|~|_|~|__|~~~.....
 当发送0xAA时波形为：....~~~|__|~|_|~|_|~|_|~|_|~~~.....
	这样无论传输什么数据，都会有2个低电平，避免与规律波形的数据重合
 
	EFM32端，
	leuart使能接收和startFrame中断，
 当产生startFrame中断时，唤醒
 当只产生接收中断时，读取数据，扔掉，不唤醒系统
	当需要待机时，自己无任务处理，并判断多少时间没有有效通讯
 
 
 
	编入通讯数据前，必须有一段时间的持续电平【R&L比较后要为高，等同uart无数据】，
 持续时间在一个字节以上，以便让接收方认为无数据【无start bit】
	uart时序：start bit[low]，8bit数据，parity bit，stop bit[high]
 
 
	数据编码：暂定L:R，L>R--HIGH, L<R--LOW电平
	一个bit的电平，需要sample数为：48000/4800=10个sample
	无效数据段，要一个11bit以上的高电平：11*10=110个sample
 
 */

int bit2Pcm(U8 bit, signed short *pPcmData)
{
    int i;
    signed short left, right;
    signed short *pcm = pPcmData;
    
    /* L>R--HIGH, L<R--LOW电平 */
    if (bit == 0)
    {
        /* 低电平 */
        left	= WAVE_SAMPLE_VAL_MIN;
        right	= WAVE_SAMPLE_VAL_MAX;
    }
    else
    {
        /* 高电平 */
        left	= WAVE_SAMPLE_VAL_MAX;
        right	= WAVE_SAMPLE_VAL_MIN;
    }
    //DEBUG(printf(" *bit* %d\r\n", bit);)
    
    /* 填充pcm数据 */
    for (i=0; i<WAVE_SAMPLE_REPEAT_CNT_SIGNAL; i++)
    {
        *pcm++ = left;	//left
        *pcm++ = right;	//right
    }
    
    //pPcmData = pcm;
    
    return WAVE_SAMPLE_REPEAT_CNT_SIGNAL*2;
}

int data2Pcm(U8 *pData, int dataLen, signed short *pPcmData)
{
    int i, j, cnt, sample_cnt;
    U8 data, bit, parity;
    signed short *pcm = pPcmData;
    //LOGD("########## dataLen = %d", dataLen);
    sample_cnt = 0;
    /* 无效数据段，高电平 */
    //DEBUG(printf(" *invalid* \r\n");)
    for (i=0; i<12; i++)      //每一个数据11 bit
    {
        cnt = bit2Pcm(1, pcm);
        pcm += cnt;
        sample_cnt += cnt;
    }
    
    //DEBUG(printf(" *data* \r\n");)
    for (j=0; j<dataLen; j++)
    {
        data = pData[j];
        /* start bit */
        cnt = bit2Pcm(0, pcm);
        pcm += cnt;
        sample_cnt += cnt;
        
        parity = 0;
        //DEBUG(printf(" *data* 0x%02X\r\n", data);)
        /* 8bit data，低位先 */
        for (i=0; i<8; i++)
        {
            bit = data&0x01;
            cnt = bit2Pcm(bit, pcm);
            pcm += cnt;
            sample_cnt += cnt;
            data = data>>1;
            
            if (bit)
                parity++;
        }
        
        //DEBUG(printf(" *parity* \r\n");)
        /* parity bit */
        cnt = bit2Pcm((parity&0x01), pcm);	//even 偶校验
        //cnt = bit2Pcm(!(parity&0x01), pcm);	//odd 奇校验
        pcm += cnt;
        sample_cnt += cnt;
        
        /* stop bit *2 */
        //DEBUG(printf(" *stop* \r\n");)
        for (i=0; i<4; i++)
        {
            cnt = bit2Pcm(1, pcm);
            pcm += cnt;
            sample_cnt += cnt;
        }
    }
    //LOGD("########## sample_cnt = %d", sample_cnt);
    return sample_cnt;
}

extern int fileDataBytes;
tWAVE_HEADER tWav_header;
signed short *pcmData;
int wavemake(U8 fileBytes[], int fileBytesLen, U8 wavedata[], int wavedataLen)
{
    int i, j;
    signed short left, right;
    int repeatCnt;
    U8 data[256];
    int samples_preCh;  //时间段单声道采样点数
    int insertFlag = 0;
    
    samples_preCh = WAVE_TIME_ALL*WAVE_SAMPLE_RATE/2;// Seconds * 48000表示0.5秒采样的ADC点数
    /* wav文件固定标识 */
    memcpy(&tWav_header.RiffID[0], "RIFF", 4);
    memcpy(&tWav_header.RiffFormat[0], "WAVE", 4);
    memcpy(&tWav_header.FmtID[0], "fmt ", 4);
    memcpy(&tWav_header.DataID[0], "data", 4);
    
    tWav_header.FmtSize			= 16;		//PCM
    tWav_header.FormatTag		= 1;		//非压缩格式
    tWav_header.Channels		= 2;		//双通道
    
    tWav_header.BitsPerSample	= 16;		//每个sample 16bit
    tWav_header.SamplesPerSec	= WAVE_SAMPLE_RATE;	//44.1kHz
    tWav_header.AvgBytesPerSec	= tWav_header.SamplesPerSec*tWav_header.Channels*tWav_header.BitsPerSample/8;//采样率*双通道*2Byte = 每秒总字节数
    tWav_header.BlockAlign		= tWav_header.Channels*tWav_header.BitsPerSample/8;//双通道*2Byte = 4Byte对齐
    
    tWav_header.DataSize		= samples_preCh*tWav_header.BlockAlign; 	//数据size(字节) 采样时间*采样率*双通道4字节=总数据大小
    tWav_header.RiffSize		= tWav_header.DataSize+sizeof(tWAVE_HEADER)-8;	//文件size-8(字节)
    
    pcmData = (signed short *)malloc(samples_preCh*tWav_header.Channels*2+128*1024);
    //pcmData = (signed short *)malloc(samples_preCh*tWav_header.Channels*64);
    /* 填充数据 */
#ifdef L_R_DIFF
    left	= WAVE_SAMPLE_VAL_MAX;//正数最大值32767
    right	= WAVE_SAMPLE_VAL_MIN;//负数最大值32768
#else
    left	= WAVE_SAMPLE_VAL_MAX;
    right	= WAVE_SAMPLE_VAL_MAX;
#endif
    repeatCnt = WAVE_SAMPLE_REPEAT_CNT;//5			波形半周期采样点数
    //LOGI("开始转换");
    for (i=0; i<samples_preCh*tWav_header.Channels;)//单通道ADC点数总和*双通道  i=采样点位置
    {
        /* 每个通道重复4个数据 */
        for (j=0; j<repeatCnt; j++)//48
        {
            /* 左、右声道反向 */
            pcmData[i+j*tWav_header.Channels]	= left;//48个左声道点+48个右声道点交叉  左声道半周期
            pcmData[i+j*tWav_header.Channels+1]	= right;//右声道半周期48个点，频率为48000/(48*2) = 500HZ
        }
        
        i += repeatCnt*tWav_header.Channels;   //i+2
        
        if (repeatCnt == WAVE_SAMPLE_REPEAT_CNT1)
        {
            repeatCnt = WAVE_SAMPLE_REPEAT_CNT;
        }
        else
        {
            repeatCnt = WAVE_SAMPLE_REPEAT_CNT1;
        }														//半周期完成
#ifdef L_R_DIFF	//该宏定义下的逻辑用于生成指令波形
        if (left == WAVE_SAMPLE_VAL_MAX)
        {
            /* 数据反向 */
            left	= WAVE_SAMPLE_VAL_MIN;
            right	= WAVE_SAMPLE_VAL_MAX;
        }
        else
        {
            /* 插入数据 */
            int samples_insertSignal;
            samples_insertSignal = WAVE_TIME_INSERT_SIGNAL*WAVE_SAMPLE_RATE/100*3* tWav_header.Channels; //数据点开始index设置
            if (i>=samples_insertSignal && insertFlag == 0) {
                insertFlag = 1;
                
#if 0
                //data[0] = 0x55;
                data[0] = 0xAA;
                i += data2Pcm(data, 1, &pcmData[i]);
#else
                /* 扫描触发命令 */
                //data[0] = COMM_WAKEUP_START_BYTE;
                //LOGI("111111");
                memcpy( &data[0], fileBytes, fileBytesLen);
                //LOGI("转换当前段");
                //				for (int i = 0; i < 4; i++)
                //				{
                //					LOGI("string %X", data[i], 1024);//去字符串s%
                //				}
                i += data2Pcm(data, fileBytesLen , &pcmData[i]);        //跳过插入数据点区段
                //LOGD("########## fileBytesLen = %d", fileBytesLen);
#endif
            }
            
            left	= WAVE_SAMPLE_VAL_MAX;
            right	= WAVE_SAMPLE_VAL_MIN;
        }
#else		//下面的逻辑用于生成固定频率的蜂鸣器音频
        if (left == WAVE_SAMPLE_VAL_MAX)
        {
            /* 数据反向 */
            left	= WAVE_SAMPLE_VAL_MIN;
            right	= WAVE_SAMPLE_VAL_MIN;
        }
        else
        {
            left	= WAVE_SAMPLE_VAL_MAX;
            right	= WAVE_SAMPLE_VAL_MAX;
        }
#endif
    }
    //LOGI("转换当前段");
    memcpy(wavedata,(char *)pcmData,samples_preCh*tWav_header.Channels*2);
    wavedataLen = samples_preCh*tWav_header.Channels *2;
    
    //	(*env)->ReleaseByteArrayElements(env, fileBytes, Bytes, 0);
    //	(*env)->ReleaseByteArrayElements(env, wavedata, wave, 0);
    //LOGI("back");
    return wavedataLen;
}
