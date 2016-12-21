//
//  NSQueue.m
//  X264CodeDemo
//
//  Created by syx on 10/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSQueue.h"


@implementation NSQueue  

@synthesize count;  

- (id)init  
{  
    if( self=[super init] )  
    {  
        m_array = [[NSMutableArray alloc] init];  
        count = 0;  
    }  
    return self;  
}  


- (void)enqueue:(id)anObject  
{  
    [m_array addObject:anObject];  
    count = m_array.count;  
}  
- (id)dequeue  
{  
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
    id obj = nil;  
    if(m_array.count > 0)  
    {  
        obj = [m_array objectAtIndex:0];  
        [m_array removeObjectAtIndex:0];  
        count = m_array.count;  
    }  
    //[pool release];
    return obj;  
}  

- (void)clear  
{  
    [m_array removeAllObjects];  
    count = 0;  
}  

@end  



