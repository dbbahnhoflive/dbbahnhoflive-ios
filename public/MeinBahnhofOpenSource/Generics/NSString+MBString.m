// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "NSString+MBString.h"
#import <CommonCrypto/CommonDigest.h>
#import "MBUIHelper.h"

@implementation NSString (MBString)

- (NSString *)MD5String
{
    const char *cstr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (int)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}

- (NSMutableAttributedString*) rawHtmlString
{
    NSError *error;
    
    NSDictionary *dict = @{
                           NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                           NSCharacterEncodingDocumentAttribute:  @(NSUTF8StringEncoding)
                           };
    
    NSMutableAttributedString *mutableHTML = [[NSMutableAttributedString alloc]
                                              initWithData: [self dataUsingEncoding:NSUTF8StringEncoding]
                                              options: dict
                                              documentAttributes:&dict
                                              error: &error];
    if (error) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }
    return mutableHTML;
}


- (NSMutableAttributedString*) attributedHtmlString
{
    NSMutableParagraphStyle *defaultParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [defaultParagraphStyle setParagraphSpacing:defaultParagraphStyle.paragraphSpacing+5];
    
    NSDictionary *dict = @{
                           NSFontAttributeName: [UIFont db_RegularFourteen],
                           NSCharacterEncodingDocumentAttribute:  @(NSUTF8StringEncoding),
                           NSForegroundColorAttributeName:[UIColor db_333333],
                           NSParagraphStyleAttributeName:defaultParagraphStyle
                           };
    
    NSMutableString* html = [self mutableCopy];
    
    NSMutableArray<NSValue*>* attributeRanges = [NSMutableArray arrayWithCapacity:20];
    NSMutableArray<NSDictionary*>* attributeDict = [NSMutableArray arrayWithCapacity:20];

    //we only support <p>, <br>, <ul><li></ul> and <a> tags!
    [html replaceOccurrencesOfString:@"<p>" withString:@"" options:0 range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"</p>" withString:@"\n\n" options:0 range:NSMakeRange(0, html.length)];
    [html replaceOccurrencesOfString:@"<br>" withString:@"\n" options:0 range:NSMakeRange(0, html.length)];
    //[html replaceOccurrencesOfString:@"<br/>" withString:@"\n" options:0 range:NSMakeRange(0, html.length)];
    //[html replaceOccurrencesOfString:@"</br>" withString:@"\n" options:0 range:NSMakeRange(0, html.length)];
    while([html hasSuffix:@"\n"]){
        [html deleteCharactersInRange:NSMakeRange(html.length-1, 1)];
    }
    while([html hasPrefix:@"\n"]){
        [html deleteCharactersInRange:NSMakeRange(0, 1)];
    }

    //NSLog(@"parse html %@",html);
    NSInteger index = 0;
    while(index < html.length){
        //NSLog(@"parse: %@",[html substringFromIndex:index]);
        NSUInteger location = [html rangeOfString:@"<" options:0 range:NSMakeRange(index, html.length-index)].location;
        if(location == NSNotFound){
            break;//done
        }
        if([html characterAtIndex:location+1]=='a'){
            //"<a... this is a link
            NSUInteger endOpenTag = [html rangeOfString:@">" options:0 range:NSMakeRange(location+1, html.length-location-1)].location;
            if(endOpenTag == NSNotFound){
                //bad format, stop
                NSLog(@"bad format: %@",html);
                index = html.length;
            } else {
                //get the href="..."
                NSRange href = [html rangeOfString:@"href=\"" options:0 range:NSMakeRange(location, endOpenTag-location)];
                if(href.location == NSNotFound){
                    //bad format, stop
                    NSLog(@"bad format: %@",html);
                    index = html.length;
                } else {
                    NSUInteger hrefEnd = [html rangeOfString:@"\"" options:0 range:NSMakeRange(href.location+href.length, html.length-(href.location+href.length))].location;
                    if(hrefEnd == NSNotFound){
                        //bad format, stop
                        NSLog(@"bad format: %@",html);
                        index = html.length;
                    } else {
                        NSString* hrefString = [html substringWithRange:NSMakeRange(href.location+href.length, hrefEnd-(href.location+href.length))];
                        //NSLog(@"hrefString %@",hrefString);
                        NSRange endTag = [html rangeOfString:@"</a>" options:0 range:NSMakeRange(location+1, html.length-location-1)];
                        if(endTag.location == NSNotFound){
                            NSLog(@"bad format: %@",html);
                            index = html.length;
                        } else {
                            NSString* linkString = [html substringWithRange:NSMakeRange(endOpenTag+1, endTag.location-(endOpenTag+1))];
                            //NSLog(@"link string %@",linkString);
                            [html replaceCharactersInRange:NSMakeRange(location, endTag.location+endTag.length-location) withString:linkString];
                            
                            [attributeRanges addObject:[NSValue valueWithRange:NSMakeRange(location, linkString.length)]];
                            [attributeDict addObject:@{NSLinkAttributeName:hrefString}];
                            
                            index = location+linkString.length;
                        }
                    }
                }
            }
        } else {
            //expecting some characters and a closing ">"
            NSUInteger endOpenTag = [html rangeOfString:@">" options:0 range:NSMakeRange(location+1, html.length-location-1)].location;
            if(endOpenTag == NSNotFound){
                //bad format, stop
                NSLog(@"bad format: %@",html);
                index = html.length;
            } else {
                NSString* tagName = [html substringWithRange:NSMakeRange(location+1, endOpenTag-location-1)];
                //NSLog(@"open tag %@",tagName);
                NSString* closeTagString = [NSString stringWithFormat:@"</%@>",tagName];
                NSUInteger closeTag = [html rangeOfString:closeTagString options:0 range:NSMakeRange(endOpenTag+1, html.length-endOpenTag-1)].location;
                if([tagName isEqualToString:@"ul"]){
                    NSInteger startTextIndex = location+1+tagName.length+1;
                    NSRange tableRange = NSMakeRange(startTextIndex, closeTag-startTextIndex);
                    NSMutableString* tableString = [[html substringWithRange:tableRange] mutableCopy];
                    //NSLog(@"extracted tableString: %@",tableString);
                    //now we insert a newline, a single rectangular shape and a tab for each list item:
                    NSString* listDot = @"\u25A0";
                    [tableString replaceOccurrencesOfString:@"<li>" withString:[NSString stringWithFormat:@"\n%@\t",listDot] options:0 range:NSMakeRange(0, tableString.length)];
                    [tableString replaceOccurrencesOfString:@"</li>" withString:@"" options:0 range:NSMakeRange(0, tableString.length)];
                    [html replaceCharactersInRange:NSMakeRange(tableRange.location-4, tableRange.length+4+5) withString:tableString];//replace "<ul>...</ul>" with formated items
                    
                    //create special format for list styles
                    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
                    [paragraphStyle setTabStops:@[[[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentLeft location:15 options:@{}]]];
                    [paragraphStyle setDefaultTabInterval:15];
                    [paragraphStyle setFirstLineHeadIndent:0];
                    [paragraphStyle setHeadIndent:15];
                    [paragraphStyle setParagraphSpacing:paragraphStyle.paragraphSpacing+5];
                    
                    [attributeRanges addObject:[NSValue valueWithRange:NSMakeRange(location, tableString.length)]];
                    [attributeDict addObject:@{NSParagraphStyleAttributeName: paragraphStyle}];
                    
                    //change the font and color for the list dot:
                    NSRange dot = NSMakeRange(0, 0);
                    while(dot.location < tableString.length && (dot = [tableString rangeOfString:listDot options:0 range:NSMakeRange(dot.location, tableString.length-dot.location)]).location != NSNotFound){
                        [attributeDict addObject:@{NSFontAttributeName:[UIFont db_RegularEight],
                                                   NSForegroundColorAttributeName:[UIColor dbColorWithRGB:0x9A9EA5]
                                                   }];
                        [attributeRanges addObject:[NSValue valueWithRange:NSMakeRange(location+dot.location,dot.length)]];
                        
                        dot = NSMakeRange(dot.location+dot.length, 0);//len is not used
                    }
                    index = location+tableString.length;//NOTE: items in <ul></ul> cant contain other tags!
                } else if([tagName isEqualToString:@"b"]){
                    [html deleteCharactersInRange:NSMakeRange(location, 3)];//delete start tag
                    [html deleteCharactersInRange:NSMakeRange(closeTag-3, 4)];
                    [attributeDict addObject:@{NSFontAttributeName: [UIFont db_BoldFourteen] }];
                    [attributeRanges addObject:[NSValue valueWithRange:NSMakeRange(location,closeTag-3-location)]];
                    index = closeTag-(3+4);//we removed the tags
                } else if([tagName isEqualToString:@"i"]){
                    [html deleteCharactersInRange:NSMakeRange(location, 3)];//delete start tag
                    [html deleteCharactersInRange:NSMakeRange(closeTag-3, 4)];
                    
                    [attributeDict addObject:@{NSFontAttributeName: [UIFont db_ItalicWithSize:14] }];
                    [attributeRanges addObject:[NSValue valueWithRange:NSMakeRange(location,closeTag-3-location)]];
                    index = closeTag-(3+4);//we removed the tags
                } else {
                    if(closeTag == NSNotFound){
                        //bad format, stop
                        NSLog(@"bad format: %@",html);
                        index = html.length;
                    } else {
                        //skip
                        NSLog(@"WARNING, unexpected tag skipped: %@",tagName);
                        index = closeTag+1;
                    }
                }
            }
        }
    }
    
    NSMutableAttributedString *mutableHTML = [[NSMutableAttributedString alloc]
                                              initWithString:html attributes:dict];
    NSInteger attindex = 0;
    for(NSValue* value in attributeRanges){
        NSRange range = value.rangeValue;
        NSDictionary* newAttributes = attributeDict[attindex];
        NSDictionary* oldAttributes = [mutableHTML attributesAtIndex:range.location effectiveRange:NULL];
        NSMutableDictionary* mergedAttr = [oldAttributes mutableCopy];
        [mergedAttr addEntriesFromDictionary:newAttributes];
        [mutableHTML setAttributes:mergedAttr range:range];
        attindex++;
    }
    
    return mutableHTML;
}

- (NSAttributedString*) convertFonts:(NSDictionary*)options
{
    NSMutableAttributedString *tempString = [self attributedHtmlString];
    NSRange range = (NSRange){0,[tempString length]};
    [tempString enumerateAttribute:NSFontAttributeName inRange:range options:NSAttributedStringEnumerationReverse usingBlock:^(id value, NSRange range, BOOL *stop) {
        UIFont *replacementFont = [options objectForKey:@"replacementFont"];
        [tempString addAttribute:NSFontAttributeName value:replacementFont range:range];
        [tempString addAttribute:NSForegroundColorAttributeName value:[options objectForKey:@"color"] range:range];
    }];
    return tempString;
}

- (CGSize) calculateSizeConstrainedTo:(CGSize)constraints
{
    UIFont *font = [UIFont db_HelveticaTwelve];
    
    return  [self calculateSizeConstrainedTo:constraints andFont:font];
}

- (CGSize) calculateSizeConstrainedTo:(CGSize)constraints andFont:(UIFont*)font
{
    CGSize constraintSize = constraints;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    CGSize size = [self boundingRectWithSize:constraintSize
                                     options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attrDict context:nil].size;
    return size;
}

- (CGFloat)fontSizeWithFont:(UIFont *)font constrainedToSize:(CGSize)size
{
    CGFloat fontSize = [font pointSize];
    CGFloat height = [self boundingRectWithSize:CGSizeMake(size.width,FLT_MAX)
                                     options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{NSFontAttributeName: font} context:nil].size.height;
    UIFont *newFont = font;
    
    //Reduce font size while too large, break if no height (empty string)
    while (height > size.height && height != 0) {
        fontSize--;
        newFont = [UIFont fontWithName:font.fontName size:fontSize];
        height = [self boundingRectWithSize:CGSizeMake(size.width,FLT_MAX)
                                    options:NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin
                                 attributes:@{NSFontAttributeName: newFont} context:nil].size.height;
    };
    
    // Loop through words in string and resize to fit
    for (NSString *word in [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]) {
        CGFloat width = [word sizeWithAttributes:@{NSFontAttributeName: newFont}].width;
        while (width > size.width && width != 0) {
            fontSize--;
            newFont = [UIFont fontWithName:font.fontName size:fontSize];
            width = [word sizeWithAttributes:@{NSFontAttributeName: newFont}].width;
        }
    }
    return fontSize;
}

@end
