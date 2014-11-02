//
//  UIBusIcon.m
//  riobus
//
//  Created by Vitor Marques de Miranda on 01/11/14.
//  Copyright (c) 2014 Rio Bus. All rights reserved.
//

#import "UIBusIcon.h"

@implementation UIImage (SuperUIImage)
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
@end

@implementation UIBusIcon

+(BOOL)isRetina{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
        ([UIScreen mainScreen].scale == 2.0)) return TRUE;
    else return FALSE;
}
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
+(CGFloat)widthOfString:(NSString*)string withFont:(UIFont*)font{
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
    return [[[NSAttributedString alloc] initWithString:string attributes:attributes] size].width;
}

+(UIImage*)ipMaskedImageNamed:(NSString *)name color:(UIColor *)color{
    UIImage *image = [UIImage imageNamed:name];
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, image.scale);
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    [image drawInRect:rect];
    
    CGContextSetFillColorWithColor(c, [color CGColor]);
    CGContextSetBlendMode(c, kCGBlendModeSourceAtop);
    CGContextFillRect(c, rect);
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}
+(UIImage*)drawText:(NSString*)text inImage:(UIImage*)image withColor:(UIColor*)textColor{
    UIFont *font = [UIFont boldSystemFontOfSize:[UIBusIcon isRetina]?18:9];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    
    CGFloat width = [UIBusIcon widthOfString:text withFont:font];
    CGRect rect = CGRectMake((image.size.width-width)/2, [UIBusIcon isRetina]?4:2, width, image.size.height);
    
    [text drawInRect:rect withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:textColor}];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(UIImage*)iconForBusLine:(NSString*)busLine withDelay:(NSInteger)delayInformation andColor:(UIColor*)color{
    //Ler para usar novo tipo de ícone: Bitmap Images and Image Masks
    UIImage* imagem = [UIBusIcon ipMaskedImageNamed:@"bus-gray" color:color];
    
    imagem = [UIBusIcon drawText:busLine inImage:imagem withColor:[UIBusIcon textColorForBackground:color]];
    
         if (delayInformation > 10) return [imagem imageByCombiningImage:[UIImage imageNamed:@"bus-red"]];
    else if (delayInformation > 5 ) return [imagem imageByCombiningImage:[UIImage imageNamed:@"bus-yellow"]];
    else                            return [imagem imageByCombiningImage:[UIImage imageNamed:@"bus-green"]];
}

@end
