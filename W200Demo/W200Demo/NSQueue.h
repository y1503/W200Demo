//
//  NSQueue.h
//  X264CodeDemo
//
//  Created by syx on 10/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>  

@interface NSQueue : NSObject {  
    NSMutableArray* m_array;  
}  

- (void)enqueue:(id)anObject;  
- (id)dequeue;  
- (void)clear;  

@property (nonatomic, readonly) int count;  

@end  
