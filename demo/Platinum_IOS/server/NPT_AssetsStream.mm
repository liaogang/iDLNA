
#import "NPT_AssetsStream.h"

NPT_AssetsStream::NPT_AssetsStream(ALAssetRepresentation *rep):rep(rep),curr(0)
{
    assert(rep);
}

NPT_AssetsStream::~NPT_AssetsStream()
{
    rep = nil;
}

// methods
NPT_Result NPT_AssetsStream::Load(NPT_DataBuffer& buffer, NPT_Size max_read)
{
    //not implemented yet
    assert(false);
    return NPT_FAILURE;
}

NPT_Result NPT_AssetsStream::Read(void*     buffer,
                                  NPT_Size  bytes_to_read,
                                  NPT_Size* bytes_read )
{
    assert(rep);
    
    NSError *error = nil;
    *bytes_read = (NPT_Size)[rep getBytes:(uint8_t *)buffer fromOffset:(NSUInteger)curr length:(NSUInteger)bytes_to_read error: &error];
    
    curr += *bytes_read;
    
    if (error)
        return NPT_FAILURE;
    
    return NPT_SUCCESS;
}

NPT_Result NPT_AssetsStream::ReadFully(void* buffer, NPT_Size  bytes_to_read)
{
    assert(rep);
    
    NPT_Size bytes_readed = 0;
    
    NSError *error = nil;
    while (bytes_readed < bytes_to_read) {
        
        bytes_readed += [rep getBytes:(uint8_t *)buffer fromOffset:curr length:bytes_to_read - bytes_readed error:&error];
        
        curr += bytes_readed;
        
        if (error)
            return NPT_FAILURE;
    }
    
    
    return NPT_SUCCESS;
}

NPT_Result NPT_AssetsStream::Seek(NPT_Position offset)
{
    curr = offset;
    return NPT_SUCCESS;
}

NPT_Result NPT_AssetsStream::Skip(NPT_Size offset)
{
    curr += offset;
    
    return NPT_SUCCESS;
}

NPT_Result NPT_AssetsStream::Tell(NPT_Position& offset)
{
    offset = curr;
    return NPT_SUCCESS;
}

NPT_Result NPT_AssetsStream::GetSize(NPT_LargeSize& size)
{
    size = [rep size];
    return NPT_SUCCESS;
}

NPT_Result NPT_AssetsStream::GetAvailable(NPT_LargeSize& available)
{
    available = [rep size] - curr;
    return NPT_SUCCESS;
}
