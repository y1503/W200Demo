//
//  jiema.c
//  W200Demo
//
//  Created by 鱼鱼 on 16/8/25.
//  Copyright © 2016年 鱼鱼. All rights reserved.
//

#include "jiema.h"

#define BUFF_LENGTH		2048000
SInt16 adcBuffer[BUFF_LENGTH];
int remainLen = 0;

typedef unsigned char U8;
typedef SInt16 S16;

//这个方法的每个参数和返回值都代表什么
int audioInterface_wav2digital(S16 *x, int n, U8 *pdata)
{
    int i,saveStartIndex = 0;
    U8 ruler = 0,counterPos = 0,counterNeg = 0,counterTotal = 0,preFix = 0,suffix = 0,bitType = 0,bitMoveIndex = 0;
    U8 dataIndex = 0,normalDir = 0,waveFreq = 0,startBit = 0,stopBit = 0,oldCounterNeg = 0,downTremble = 0;
    U8 data[256],decodeDataLen = 0;
    memset(data,0,sizeof(data));
    if (remainLen > 0)
    {
        memcpy(&adcBuffer[remainLen],x,n*sizeof(S16));
        n += remainLen;
        remainLen = 0;
    }
    else
    {
        memcpy(adcBuffer,x,n*sizeof(S16));
    }
    if (x == NULL || pdata == NULL )
    {
        return 0;
    }
    
    for (i = 0 ;i < n;i++)
    {
        if (ruler == 0)
            ruler = 1;
        if (counterNeg > 100)
        {
            i++;
            i--;
        }
        if (adcBuffer[i] > 0)
        {
            
            if (ruler == 2)
            {
                if ((counterNeg > 5 && counterNeg < 9) || (counterNeg > 2 && counterNeg < 6) || (counterNeg > 7 && counterNeg < 18))
                {
                    if (counterNeg < 5 && waveFreq == 2)
                    {
                        ruler = 4;
                    }
                    else
                        ruler = 3;
                }
                else if ((counterNeg < 3 ) && bitType > 0)
                {
                    ruler = 4;
                }
                else
                {
                    ruler = 0;
                    preFix = 0;
                    counterPos = 0;
                    counterNeg = 0;
                    counterTotal = 0;
                    suffix = 0;
                    bitType = 0;
                    bitMoveIndex = 0;
                    saveStartIndex = 0;
                    oldCounterNeg = 0;
                    waveFreq = 0;
                }
                
            }
            else if (ruler == 5 && bitType >0)
            {
                if (counterNeg < 3)
                {
                    counterPos += counterNeg;
                    counterNeg = oldCounterNeg;
                    oldCounterNeg = 0;
                    counterPos += 2;
                    i+=2;
                    ruler = 3;
                }
                else
                {
                    ruler = 0;
                    preFix = 0;
                    counterPos = 0;
                    counterNeg = 0;
                    counterTotal = 0;
                    suffix = 0;
                    bitType = 0;
                    bitMoveIndex = 0;
                    normalDir = 1;
                    saveStartIndex = 0;
                    oldCounterNeg = 0;
                    waveFreq = 0;
                }
                
            }
            else if (ruler == 6 && bitType == 1)
            {
                if ((counterNeg > 2 && counterNeg < 6 && waveFreq==1) || (counterNeg > 7 && counterNeg < 13 && waveFreq==2))
                {
                    counterNeg = 0;
                    ruler = 7;
                    bitType = 2;
                    dataIndex = 0;
                    bitMoveIndex = 0;
                    stopBit = 0;
                    startBit = 0;
                }
                else
                {
                    i = 0;
                    ruler = 0;
                    preFix = 0;
                    counterPos = 0;
                    counterNeg = 0;
                    counterTotal = 0;
                    suffix = 0;
                    bitType = 0;
                    bitMoveIndex = 0;
                    normalDir = 1;
                    saveStartIndex = 0;
                    oldCounterNeg = 0;
                    waveFreq = 0;
                    continue;
                }
            }
            else if (ruler == 8)
            {
                if ((counterNeg > 5 && counterNeg < 9) || (counterNeg > 2 && counterNeg < 6) || (counterNeg > 7 && counterNeg < 17))
                {
                    
                    counterTotal = counterPos + counterNeg;
                    if ((counterTotal > 11 && counterTotal < 16) || (counterTotal > 23 && counterTotal < 31 ))
                    {
                        if (bitType == 0)
                        {
                            bitType = 1;
                            saveStartIndex = i;
                        }
                        if (bitType == 1)
                        {
                            preFix++;
                        }
                        else if (bitType == 2)
                        {
                            if (waveFreq == 2 && counterTotal > 11 && counterTotal < 16 )
                            {
                                data[dataIndex] &= ~(0x01 << bitMoveIndex++);
                            }
                            else
                            {
                                data[dataIndex] |= (0x01 << bitMoveIndex++);
                            }
                            if (bitMoveIndex > 7)
                            {
                                dataIndex++;
                                bitMoveIndex = 0;
                                stopBit = 1;
                            }
                            if (suffix > 0)
                            {
                                if (++suffix > 8)
                                {
                                    dataIndex--;
                                    memcpy(&pdata[decodeDataLen],data,dataIndex);
                                    decodeDataLen += dataIndex;
                                    dataIndex = 0;
                                    ruler = 0;
                                    preFix = 0;
                                    counterPos = 0;
                                    counterNeg = 0;
                                    counterTotal = 0;
                                    suffix = 0;
                                    bitType = 0;
                                    bitMoveIndex = 0;
                                    saveStartIndex = 0;
                                    oldCounterNeg = 0;
                                    waveFreq = 0;
                                }
                            }
                        }
                        ruler = 7;
                        
                    }
                    else if ((counterTotal > 7 && counterTotal < 12 )|| (counterTotal > 15 && counterTotal < 24 ) )
                    {
                        if (bitType == 1)
                        {
                            if (preFix > 4)
                            {
                                bitType = 2;
                                dataIndex = 0;
                                bitMoveIndex = 0;
                                stopBit = 0;
                                startBit = 0;
                            }
                        }
                        else if (bitType == 2)
                        {
                            if (bitMoveIndex == 0)
                            {
                                suffix = 1;
                            }
                            else
                            {
                                suffix = 0;
                            }
                            
                            if (startBit == 1 )
                            {
                                startBit = 0;
                            }
                            else if (stopBit == 1)
                            {
                                stopBit = 0;
                                startBit = 1;
                            }
                            else
                            {
                                data[dataIndex] &= ~(0x01 << bitMoveIndex++);
                                if (bitMoveIndex > 7)
                                {
                                    dataIndex++;
                                    bitMoveIndex = 0;
                                    stopBit = 1;
                                }
                            }
                        }
                        ruler = 7;
                    }
                    else
                    {
                        memset(data,0,sizeof(data));
                        ruler = 0;
                        preFix = 0;
                        counterPos = 0;
                        counterNeg = 0;
                        counterTotal = 0;
                        suffix = 0;
                        bitType = 0;
                        bitMoveIndex = 0;
                        dataIndex = 0;
                        saveStartIndex = 0;
                        oldCounterNeg = 0;
                        waveFreq = 0;
                    }
                    
                }
                else if (counterPos < 3 && bitType == 2)
                {
                    ruler = 5;
                }
                else
                {
                    memset(data,0,sizeof(data));
                    ruler = 0;
                    preFix = 0;
                    counterPos = 0;
                    counterNeg = 0;
                    counterTotal = 0;
                    suffix = 0;
                    bitType = 0;
                    bitMoveIndex = 0;
                    dataIndex = 0;
                    saveStartIndex = 0;
                    oldCounterNeg = 0;
                    waveFreq = 0;
                }
                counterPos = 0;
                counterNeg = 0;
            }
            counterPos++;
        }
        else
        {
            if (ruler == 3)
            {
                if (bitType == 1 && preFix > 4)
                {
                    if (((counterPos > 2 && counterPos < 6) && (counterNeg > 5 && counterNeg < 9) && (counterNeg - counterPos > 0))||
                        ((counterPos > 7 && counterPos < 13) && (counterNeg > 10 && counterNeg < 17) && (counterNeg - counterPos > 2)))
                    {
                        if (normalDir == 0)
                            ruler = 6;
                    }
                }
                if (ruler != 6)
                {
                    if ((counterPos > 5 && counterPos < 9) || (counterPos > 2 && counterPos < 6) || (counterPos > 7 && counterPos < 18))
                    {
                        if (i + 2 < n)
                        {
                            if (adcBuffer[i+1] > 0 && bitType > 0 && counterNeg - counterPos > 1)
                            {
                                if (adcBuffer[i+2] > 0)
                                {
                                    counterPos+=3;
                                    i+=2;
                                }
                                else
                                {
                                    counterPos+=2;
                                    i++;
                                }
                                
                                downTremble = 1;
                                ruler = 2;
                            }
                        }
                        
                        counterTotal = counterPos + counterNeg;
                        if ((counterTotal > 11 && counterTotal < 16 ) || (counterTotal > 23 && counterTotal < 31 ))
                        {
                            if (bitType == 0)
                            {
                                bitType = 1;
                                saveStartIndex = i;
                                if (counterTotal > 11 && counterTotal < 16)
                                {
                                    waveFreq = 1;
                                }
                                else if (counterTotal > 24 && counterTotal < 31)
                                {
                                    waveFreq = 2;
                                }
                            }
                            if (bitType == 1)
                            {
                                preFix++;
                            }
                            else if (bitType == 2)
                            {
                                if (waveFreq == 2 && counterTotal > 11 && counterTotal < 16 )
                                {
                                    data[dataIndex] &= ~(0x01 << bitMoveIndex++);
                                }
                                else
                                {
                                    data[dataIndex] |= (0x01 << bitMoveIndex++);
                                }
                                
                                if (bitMoveIndex > 7)
                                {
                                    dataIndex++;
                                    bitMoveIndex = 0;
                                    stopBit = 1;
                                }
                                if (suffix > 0)
                                {
                                    if (++suffix > 8)
                                    {
                                        dataIndex--;
                                        memcpy(&pdata[decodeDataLen],data,dataIndex);
                                        decodeDataLen += dataIndex;
                                        dataIndex = 0;
                                        ruler = 0;
                                        preFix = 0;
                                        counterPos = 0;
                                        counterNeg = 0;
                                        counterTotal = 0;
                                        suffix = 0;
                                        bitType = 0;
                                        bitMoveIndex = 0;
                                        saveStartIndex = 0;
                                        oldCounterNeg = 0;
                                        waveFreq = 0;
                                    }
                                }
                            }
                            ruler = 2;
                            
                        }
                        else if ((counterTotal > 7 && counterTotal < 12 )|| (counterTotal > 15 && counterTotal < 24) )
                        {
                            if (bitType == 1)
                            {
                                if (preFix > 8)
                                {
                                    bitType = 2;
                                    dataIndex = 0;
                                    bitMoveIndex = 0;
                                    stopBit = 0;
                                    startBit = 0;
                                    
                                }
                            }
                            else if (bitType == 2)
                            {
                                if (bitMoveIndex == 0)
                                {
                                    suffix = 1;
                                }
                                else
                                {
                                    suffix = 0;
                                }
                                if (startBit == 1 )
                                {
                                    startBit = 0;
                                }
                                else if (stopBit == 1)
                                {
                                    stopBit = 0;
                                    startBit = 1;
                                }
                                else
                                {
                                    data[dataIndex] &= ~(0x01 << bitMoveIndex++);
                                    if (bitMoveIndex > 7)
                                    {
                                        dataIndex++;
                                        bitMoveIndex = 0;
                                        stopBit = 1;
                                        if (dataIndex == 17)
                                        {
                                            i++;
                                            i--;
                                        }
                                    }
                                }
                                
                            }
                            ruler = 2;
                        }
                        else
                        {
                            memset(data,0,sizeof(data));
                            ruler = 0;
                            preFix = 0;
                            counterPos = 0;
                            counterNeg = 0;
                            counterTotal = 0;
                            suffix = 0;
                            bitType = 0;
                            bitMoveIndex = 0;
                            dataIndex = 0;
                            saveStartIndex = 0;
                            oldCounterNeg = 0;
                            waveFreq = 0;
                        }
                        
                    }
                    else if (counterPos < 3 && bitType > 0)
                    {
                        ruler = 5;
                        oldCounterNeg = counterNeg;
                    }
                    else
                    {
                        memset(data,0,sizeof(data));
                        ruler = 0;
                        preFix = 0;
                        counterPos = 0;
                        counterNeg = 0;
                        counterTotal = 0;
                        suffix = 0;
                        bitType = 0;
                        bitMoveIndex = 0;
                        dataIndex = 0;
                        saveStartIndex = 0;
                        oldCounterNeg = 0;
                        waveFreq = 0;
                    }
                }
                if (ruler != 5)
                {
                    counterPos = 0;
                    
                }
                counterNeg = 0;
                
            }
            else if (ruler == 4 && bitType > 0)
            {
                if (counterPos < 4)
                {
                    counterNeg+= counterPos;
                    counterPos = 0;
                    if (i + 3 < n && waveFreq == 2)
                    {
                        counterNeg += 3;
                        i += 3;
                    }
                    ruler = 2;
                }
                else
                {
                    memset(data,0,sizeof(data));
                    ruler = 0;
                    preFix = 0;
                    counterPos = 0;
                    counterNeg = 0;
                    counterTotal = 0;
                    suffix = 0;
                    bitType = 0;
                    bitMoveIndex = 0;
                    dataIndex = 0;
                    saveStartIndex = 0;
                    oldCounterNeg = 0;
                    waveFreq = 0;
                }
            }
            else if (ruler == 7)
            {
                if ((counterPos > 4 && counterPos < 9) || (counterPos > 2 && counterPos < 7) || (counterPos > 7 && counterPos < 17))
                {
                    //counterNeg = 0;
                    ruler = 8;
                }
                else if (counterPos < 3 && bitType == 2)
                {
                    ruler = 5;
                }
                else 
                {
                    memset(data,0,sizeof(data));
                    ruler = 0;
                    preFix = 0;
                    counterPos = 0;
                    counterNeg = 0;
                    counterTotal = 0;
                    suffix = 0;
                    bitType = 0;
                    bitMoveIndex = 0;
                    dataIndex = 0;
                    saveStartIndex = 0;
                    oldCounterNeg = 0;
                    waveFreq = 0;
                }
            }
            if (downTremble == 1)
            {
                downTremble = 0;
            }
            else
            {
                counterNeg++;
            }
            
            if (ruler == 1)
            {
                if (counterPos > 0) 
                {
                    counterPos = 0;
                    ruler = 2;
                    
                }
            }
            
        }
    }
    if (saveStartIndex > 0)
    {
        if (saveStartIndex > 100)
        {
            saveStartIndex -= 100;
        }
        else
        {
            saveStartIndex = 0;
        }
        
        remainLen = n - saveStartIndex;
        if (remainLen<<1 < BUFF_LENGTH)
        {
            
            memcpy(adcBuffer,&adcBuffer[saveStartIndex],remainLen*sizeof(S16));
        }
        else 
        {
            
        }
    }
    return decodeDataLen;
}
