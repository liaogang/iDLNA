//
//  id3Info.h
//
//  Created by liaogang on 6/20/14.
//
//

#import <Foundation/Foundation.h>


/**
 *  get audio file's id3 info.
 *  @param audioFile: input
 *  @param album,artist,title: output info
 *  @return audio's album image.(封面图)
 */

//BOOL getId3FromAudio(NSURL *audioFile,
//                     NSMutableString *artist,
//                     NSMutableString *album,
//                     NSMutableString *title,
//                     NSMutableString *genre,
//                     NSMutableString *year,
//                     NSMutableData *image /*could be nil*/ ,
//                     NSMutableString *lyrics/*could be nil*/);

NSData * getId3ImageFromAudio(NSURL *audioFile);

NSString *getAudioLyrics(NSURL *audioFile);





