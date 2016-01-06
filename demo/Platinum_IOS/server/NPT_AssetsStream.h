
#import <Platinum/Platinum.h>
#import <AssetsLibrary/AssetsLibrary.h>

/** read streams from a file in the device assets library
 @see ALAssetsLibrary
 */
class NPT_AssetsStream :public NPT_InputStream
{
private:
    __strong ALAssetRepresentation *rep;
    NPT_Position curr; //current read pointer.
public:
    // constructor and destructor
    NPT_AssetsStream(ALAssetRepresentation *rep);
    ~NPT_AssetsStream();
    
    // methods
    
    /// read data from stream to the the buffer(we will alloc one).
    NPT_Result Load(NPT_DataBuffer& buffer, NPT_Size max_read = 0);
    
    NPT_Result Read(void* buffer, NPT_Size  bytes_to_read, NPT_Size* bytes_read = NULL) ;
    
    /// means read untill the buffer fulled. bytes_read == bytes_to_read.
    NPT_Result ReadFully(void* buffer, NPT_Size  bytes_to_read);
    NPT_Result Seek(NPT_Position offset) ;
    NPT_Result Skip(NPT_Size offset);
    NPT_Result Tell(NPT_Position& offset) ;
    NPT_Result GetSize(NPT_LargeSize& size) ;
    NPT_Result GetAvailable(NPT_LargeSize& available) ;
};

