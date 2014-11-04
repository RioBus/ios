//
//  UIBusIcon.m
//  riobus
//
//  Created by Vitor Marques de Miranda on 01/11/14.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "UIBusIcon.h"

@implementation UIImage (UIBusIconImage)
-(UIImage*)imageByCombiningImage:(UIImage*)firstImage{
    UIImage *image = nil;
    
    CGSize newImageSize = CGSizeMake(self.size.width,self.size.height);
    if (UIGraphicsBeginImageContextWithOptions != NULL) {
        UIGraphicsBeginImageContextWithOptions(newImageSize, NO, [[UIScreen mainScreen] scale]);
    } else {
        UIGraphicsBeginImageContext(newImageSize);
    }
    
    [self drawAtPoint:CGPointMake(roundf((newImageSize.width-self.size.width)/2),
                                        roundf((newImageSize.height-self.size.height)/2))];
    [firstImage drawAtPoint:CGPointMake(roundf((newImageSize.width-firstImage.size.width)/2),
                                         roundf((newImageSize.height-firstImage.size.height)/2))];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
-(UIImage*)imageByMaskingImageWithColor:(UIColor*)color{
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, self.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    [self drawInRect:rect];
    
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}
-(UIImage*)imageByWritingText:(NSString*)text withColor:(UIColor*)textColor{
    BOOL isRetina = ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
                     ([UIScreen mainScreen].scale == 2.0));
    
    UIFont *font = [UIFont boldSystemFontOfSize:isRetina?18:9];
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0,0,self.size.width,self.size.height)];
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    CGFloat width = [[[NSAttributedString alloc] initWithString:text attributes:attributes] size].width;
    CGRect rect = CGRectMake((self.size.width-width)/2, isRetina?4:2, width, self.size.height);
    
    [text drawInRect:rect withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:textColor}];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
@end

@implementation UIColor (UIBusIconColor)
-(UIColor*)foregroundColor{
    CGFloat grayScale;
    
    CGColorRef color = [self CGColor];
    unsigned long numComponents = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    grayScale = components[0];
    
    if (numComponents == 4){
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        grayScale = red*0.299 + green*0.587 + blue*0.114;
    }
    
    if (grayScale<0.5) return [UIColor whiteColor];
    else return [UIColor blackColor];
}
@end

@implementation UIBusIcon

+(UIColor*)textColorForBackground:(UIColor*)backColor{
    CGFloat grayScale;
    
    CGColorRef color = [backColor CGColor];
    unsigned long numComponents = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    grayScale = components[0];
    
    if (numComponents == 4){
        CGFloat red = components[0];
        CGFloat green = components[1];
        CGFloat blue = components[2];
        grayScale = red*0.299 + green*0.587 + blue*0.114;
    }
    
    if (grayScale<0.5) return [UIColor whiteColor];
    else return [UIColor blackColor];
}
+(UIImage*)iconForBusLine:(NSString*)busLine withDelay:(NSInteger)delayInformation andColor:(UIColor*)color{
    //Ler para usar novo tipo de ícone: Bitmap Images and Image Masks
    UIImage* imagem = [[UIImage imageNamed:@"bus-gray"] imageByMaskingImageWithColor:color];
    imagem = [imagem imageByWritingText:busLine withColor:[color foregroundColor]];
    
         if (delayInformation > 10) return [imagem imageByCombiningImage:[UIImage imageNamed:@"bus-red"   ]];
    else if (delayInformation > 5 ) return [imagem imageByCombiningImage:[UIImage imageNamed:@"bus-yellow"]];
    else                            return [imagem imageByCombiningImage:[UIImage imageNamed:@"bus-green" ]];
}

@end
