/*****************************************************************
|
|   Platinum - Miccro Media Controller
|
| Copyright (c) 2004-2010, Plutinosoft, LLC.
| All rights reserved.
| http://www.plutinosoft.com
|
| This program is free software; you can redistribute it and/or
| modify it under the terms of the GNU General Public License
| as published by the Free Software Foundation; either version 2
| of the License, or (at your option) any later version.
|
| OEMs, ISVs, VARs and other distributors that combine and 
| distribute commercially licensed software with Platinum software
| and do not wish to distribute the source code for the commercially
| licensed software under version 2, or (at your option) any later
| version, of the GNU General Public License (the "GPL") must enter
| into a commercial license agreement with Plutinosoft, LLC.
| licensing@plutinosoft.com
| 
| This program is distributed in the hope that it will be useful,
| but WITHOUT ANY WARRANTY; without even the implied warranty of
| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
| GNU General Public License for more details.
|
| You should have received a copy of the GNU General Public License
| along with this program; see the file LICENSE.txt. If not, write to
| the Free Software Foundation, Inc., 
| 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
| http://www.gnu.org/licenses/gpl-2.0.html
|
****************************************************************/

/*----------------------------------------------------------------------
|   includes
+---------------------------------------------------------------------*/
#include "PltMicroMediaController.h"
#include <Platinum/PltLeaks.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <vector>
#include <assert.h>

//NPT_SET_LOCAL_LOGGER("platinum.tests.micromediacontroller")

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::PLT_MicroMediaController
+---------------------------------------------------------------------*/
PLT_MicroMediaController::PLT_MicroMediaController(PLT_CtrlPointReference& ctrlPoint) :
    PLT_SyncMediaBrowserMy(ctrlPoint),
    PLT_MediaController(ctrlPoint),eventHandler(NULL),m_CurSelectIndex(-1),m_CurBrowseIndex(-1)
{
    // create the stack that will be the directory where the
    // user is currently browsing. 
    // push the root directory onto the directory stack.
    m_CurBrowseDirectoryStack.Push("0");

    PLT_MediaController::SetDelegate(this);
}

void
PLT_MicroMediaController::setEventNotifyHandler(eventNotify *eventHandler,void* custom)
{
    this->eventHandler = eventHandler;
    event_custom_data = custom;
}
/*----------------------------------------------------------------------
|   PLT_MicroMediaController::PLT_MicroMediaController
+---------------------------------------------------------------------*/
PLT_MicroMediaController::~PLT_MicroMediaController()
{
}

/*
*  Remove trailing white space from a string
*/
static void strchomp(char* str)
{
    if (!str) return;
    char* e = str+NPT_StringLength(str)-1;

    while (e >= str && *e) {
        if ((*e != ' ')  &&
            (*e != '\t') &&
            (*e != '\r') &&
            (*e != '\n'))
        {
            *(e+1) = '\0';
            break;
        }
        --e;
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::ChooseIDFromTable
+---------------------------------------------------------------------*/
/* 
 * Presents a list to the user, allows the user to choose one item.
 *
 * Parameters:
 *		PLT_StringMap: A map that contains the set of items from
 *                        which the user should choose.  The key should be a unique ID,
 *						 and the value should be a string describing the item. 
 *       returns a NPT_String with the unique ID. 
 */
const char*
PLT_MicroMediaController::ChooseIDFromTable(PLT_StringMap& table)
{
    printf("Select one of the following:\n");

    NPT_List<PLT_StringMapEntry*> entries = table.GetEntries();
    if (entries.GetItemCount() == 0) {
        printf("None available\n"); 
    } else {
        // display the list of entries
        NPT_List<PLT_StringMapEntry*>::Iterator entry = entries.GetFirstItem();
        int count = 0;
        while (entry) {
            printf("%d)\t%s (%s)\n", ++count, (const char*)(*entry)->GetValue(), (const char*)(*entry)->GetKey());
            ++entry;
        }

        int index = 0, watchdog = 3;
        char buffer[1024];

        // wait for input
        while (watchdog > 0) {
            fgets(buffer, 1024, stdin);
            strchomp(buffer);

            if (1 != sscanf(buffer, "%d", &index)) {
                printf("Please enter a number\n");
            } else if (index < 0 || index > count)	{
                printf("Please choose one of the above, or 0 for none\n");
                watchdog--;
                index = 0;
            } else {	
                watchdog = 0;
            }
        }

        // find the entry back
        if (index != 0) {
            entry = entries.GetFirstItem();
            while (entry && --index) {
                ++entry;
            }
            if (entry) {
                return (*entry)->GetKey();
            }
        }
    }

    return NULL;
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::PopDirectoryStackToRoot
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::PopDirectoryStackToRoot(void)
{
    NPT_String val;
    while (NPT_SUCCEEDED(m_CurBrowseDirectoryStack.Peek(val)) && val.Compare("0")) {
        m_CurBrowseDirectoryStack.Pop(val);
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::OnMSAdded
+---------------------------------------------------------------------*/
bool 
PLT_MicroMediaController::OnMSAdded(PLT_DeviceDataReference& device) 
{     
    // Issue special action upon discovering MediaConnect server
    PLT_Service* service;
    if (NPT_SUCCEEDED(device->FindServiceByType("urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:*", service))) {
        PLT_ActionReference action;
        PLT_SyncMediaBrowser::m_CtrlPoint->CreateAction(
            device, 
            "urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1", 
            "IsAuthorized", 
            action);
        if (!action.IsNull()) {
            action->SetArgumentValue("DeviceID", "");
            PLT_SyncMediaBrowser::m_CtrlPoint->InvokeAction(action, 0);
        }

        PLT_SyncMediaBrowser::m_CtrlPoint->CreateAction(
            device, 
            "urn:microsoft.com:service:X_MS_MediaReceiverRegistrar:1", 
            "IsValidated", 
            action);
        if (!action.IsNull()) {
            action->SetArgumentValue("DeviceID", "");
            PLT_SyncMediaBrowser::m_CtrlPoint->InvokeAction(action, 0);
        }
    }
    
    
    {
        NPT_AutoLock lock(m_MediaServers);
        m_MediaServers.Put(device->GetUUID(), device);
    }
    
    
    if (eventHandler) {
        eventHandler( event_media_server_list_changed, NULL, event_custom_data);
    }
    
    
    return true; 
}


void PLT_MicroMediaController::OnMSRemoved(PLT_DeviceDataReference& device)
{
    NPT_String uuid = device->GetUUID();
    
    printf("OnMSRemoved device removed. uuid: %s\n",(char*)uuid);
    
    {
        NPT_AutoLock lock(m_MediaServers);
        m_MediaServers.Erase(uuid);
    }
    
    {
        NPT_AutoLock lock(m_CurMediaServerLock);
        
        // if it's the currently selected one, we have to get rid of it
        if (!m_CurMediaServer.IsNull() && m_CurMediaServer == device) {
            m_CurMediaServer = NULL;
        }
    }

    if (eventHandler)
        eventHandler( event_media_server_list_changed, NULL, event_custom_data);
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::OnMRAdded
+---------------------------------------------------------------------*/
bool
PLT_MicroMediaController::OnMRAdded(PLT_DeviceDataReference& device)
{
    NPT_String uuid = device->GetUUID();
    
    printf("OnMRAdded device added. uuid: %s\n",(char*)uuid);
    
    // test if it's a media renderer
    PLT_Service* service;
    if (NPT_SUCCEEDED(device->FindServiceByType("urn:schemas-upnp-org:service:AVTransport:*", service))) {
        NPT_AutoLock lock(m_MediaRenderers);
        m_MediaRenderers.Put(uuid, device);
    }
    
    if (eventHandler)
        eventHandler( event_render_list_changed, NULL, event_custom_data);
    
    return true;
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::OnMRRemoved
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::OnMRRemoved(PLT_DeviceDataReference& device)
{
    NPT_String uuid = device->GetUUID();

    {
        NPT_AutoLock lock(m_MediaRenderers);
        m_MediaRenderers.Erase(uuid);
    }

    {
        NPT_AutoLock lock(m_CurMediaRendererLock);

        // if it's the currently selected one, we have to get rid of it
        if (!m_CurMediaRenderer.IsNull() && m_CurMediaRenderer == device) {
            m_CurMediaRenderer = NULL;
        }
    }
    
    
    if (eventHandler)
        eventHandler( event_render_list_changed, NULL , event_custom_data);

}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::OnMRStateVariablesChanged
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::OnMRStateVariablesChanged(PLT_Service*                  service,
                                                    NPT_List<PLT_StateVariable*>* vars)
{
    if ( !m_CurMediaRenderer.IsNull() )
    {
        NPT_String uuid = service->GetDevice()->GetUUID();
        if( m_CurMediaRenderer->GetUUID() == uuid && eventHandler)
            eventHandler( event_state_variables_changed, (void*)vars , event_custom_data);
    }


}

/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::OnGetVolumeResult
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::OnGetVolumeResult( NPT_Result               /* res */,
                       PLT_DeviceDataReference&  device ,
                       const char*              /* channel */,
                       NPT_UInt32				  volume ,
                       void*                    /* userdata */)
{
    if (eventHandler)
    {
        eventDataRenderControlResponse d;
        d.actionName = "GetVolume";
        d.device = device;
        d.result = &volume;
        
        eventHandler( event_rendering_control_response, (void*)&d, event_custom_data);
    }
    

}

/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::OnGetPositionInfoResult
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::OnGetPositionInfoResult(
                             NPT_Result               /* res */,
                             PLT_DeviceDataReference&  device ,
                             PLT_PositionInfo*         info ,
                             void*                    /* userdata */)
{
    if (eventHandler)
    {
        eventDataRenderControlResponse d;
        d.actionName = "GetPositionInfo";
        d.device = device;
        d.result = info;
        
        eventHandler( event_rendering_control_response, (void*)&d, event_custom_data);
    }
    
}


/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::OnGetMuteResult
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::OnGetMuteResult(
                     NPT_Result               /* res */,
                     PLT_DeviceDataReference&  device ,
                     const char*              /* channel */,
                     bool                      mute ,
                     void*                    /* userdata */)
{
    if (eventHandler)
    {
        eventDataRenderControlResponse d;
        d.actionName = "GetMute";
        d.device = device;
        d.result = &mute;
        
        eventHandler( event_rendering_control_response, (void*)&d, event_custom_data);
    }
    
}

void PLT_MicroMediaController::OnSetAVTransportURIResult(
                               NPT_Result               /* res */,
                               PLT_DeviceDataReference& /* device */,
                               void*                    /* userdata */)
{
    if(eventHandler)
        eventHandler(event_render_and_media_selected,NULL,event_custom_data);
}


/*----------------------------------------------------------------------
|   PLT_MicroMediaController::ChooseIDGetCurMediaServerFromTable
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::GetCurMediaServer(PLT_DeviceDataReference& server)
{
    NPT_AutoLock lock(m_CurMediaServerLock);

    if (m_CurMediaServer.IsNull()) {
        printf("No server selected, select one with setms\n");
    } else {
        server = m_CurMediaServer;
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::GetCurMediaRenderer
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::GetCurMediaRenderer(PLT_DeviceDataReference& renderer)
{
    NPT_AutoLock lock(m_CurMediaRendererLock);

    if (m_CurMediaRenderer.IsNull()) {
#ifdef DEBUG
        printf("No renderer selected, select one with setmr\n");
#endif
    } else {
        renderer = m_CurMediaRenderer;
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::DoBrowse
+---------------------------------------------------------------------*/
NPT_Result
PLT_MicroMediaController::DoBrowse(const char* object_id, /* = NULL */
                                   bool        metadata  /* = false */)
{
    NPT_Result res = NPT_FAILURE;
    PLT_DeviceDataReference device;
    
    GetCurMediaServer(device);
    if (!device.IsNull()) {
        NPT_String cur_object_id;
        m_CurBrowseDirectoryStack.Peek(cur_object_id);

        // send off the browse packet and block
        res = BrowseSync(
            device, 
            object_id?object_id:(const char*)cur_object_id, 
            m_MostRecentBrowseResults, 
            metadata);
    }

    return res;
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_getms
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_getms()
{
    PLT_DeviceDataReference device;
    GetCurMediaServer(device);
    if (!device.IsNull()) {
        printf("Current media server: %s\n", (const char*)device->GetFriendlyName());
    } else {
        // this output is taken care of by the GetCurMediaServer call
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_getmr
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_getmr()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        printf("Current media renderer: %s\n", (const char*)device->GetFriendlyName());
    } else {
        // this output is taken care of by the GetCurMediaRenderer call
    }
}



/*----------------------------------------------------------------------
|   PLT_MicroMediaController::ChooseDevice
+---------------------------------------------------------------------*/
PLT_DeviceDataReference
PLT_MicroMediaController::ChooseDevice(const NPT_Lock<PLT_DeviceMap>& deviceList)
{
    PLT_StringMap            _namesTable;
    PLT_DeviceDataReference* result = NULL;
    NPT_String               chosenUUID;
    NPT_AutoLock             lock(m_MediaServers);

    // create a map with the device UDN -> device Name 
    const NPT_List<PLT_DeviceMapEntry*>& entries = deviceList.GetEntries();
    NPT_List<PLT_DeviceMapEntry*>::Iterator entry = entries.GetFirstItem();
    while (entry) {
        PLT_DeviceDataReference device = (*entry)->GetValue();
        NPT_String              name   = device->GetFriendlyName();
        _namesTable.Put((*entry)->GetKey(), name);

        ++entry;
    }

    // ask user to choose
    chosenUUID = ChooseIDFromTable(_namesTable);
    if (chosenUUID.GetLength()) {
        deviceList.Get(chosenUUID, result);
    }

    return result?*result:PLT_DeviceDataReference(); // return empty reference if not device was selected
}

void PLT_MicroMediaController::startSearchDevices()
{
    PopDirectoryStackToRoot();
    
    NPT_AutoLock lock(m_MediaServers);
    m_MediaServers = GetMediaServersMap();
}

const PLT_DeviceArray PLT_MicroMediaController::GetRenderDevices()
{
    PLT_DeviceArray deviceArray;
    
    NPT_Lock<PLT_DeviceMap>& deviceList = m_MediaRenderers;
    
    // create a map with the device UDN -> device Name
    const NPT_List<PLT_DeviceMapEntry*>& entries = deviceList.GetEntries();
    NPT_List<PLT_DeviceMapEntry*>::Iterator entry = entries.GetFirstItem();
    while (entry) {
        PLT_DeviceDataReference device = (*entry)->GetValue();
        
        deviceArray.Add(device);
        
        ++entry;
    }
    
    return deviceArray;
}



/**
 Get Device list.
 */
const PLT_DeviceArray PLT_MicroMediaController::GetServerDevices()
{
    const NPT_Lock<PLT_DeviceMap>& deviceMap = m_MediaServers;
    
    PLT_DeviceArray deviceArray;
    
    // create a map with the device UDN -> device Name
    const NPT_List<PLT_DeviceMapEntry*>& entries = deviceMap.GetEntries();
    NPT_List<PLT_DeviceMapEntry*>::Iterator entry = entries.GetFirstItem();
    while (entry) {
        PLT_DeviceDataReference device = (*entry)->GetValue();
        deviceArray.Add(device);
        
        ++entry;
    }
    
    return deviceArray;
}

void PLT_MicroMediaController::ChooseDeviceWithUUID(const NPT_String &uuid)
{
    NPT_AutoLock lock(m_CurMediaServerLock);
    m_CurMediaServer = m_MediaServers[uuid];
    
    assert(!uuid.IsEmpty() && !m_CurMediaServer.IsNull());
}


/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_setms
+---------------------------------------------------------------------*/
void 
PLT_MicroMediaController::HandleCmd_setms()
{
    NPT_AutoLock lock(m_CurMediaServerLock);

    PopDirectoryStackToRoot();
    m_CurMediaServer = ChooseDevice(GetMediaServersMap());
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_setmr
+---------------------------------------------------------------------*/
void 
PLT_MicroMediaController::HandleCmd_setmr()
{
    NPT_AutoLock lock(m_CurMediaRendererLock);

    m_CurMediaRenderer = ChooseDevice(m_MediaRenderers);
}

void
PLT_MicroMediaController::selectMR(int index)
{
    NPT_AutoLock lock(m_CurMediaRendererLock);
    
    NPT_Lock<PLT_DeviceMap>& deviceList = m_MediaRenderers;
    
    // create a map with the device UDN -> device Name
    const NPT_List<PLT_DeviceMapEntry*>& entries = deviceList.GetEntries();
    NPT_List<PLT_DeviceMapEntry*>::Iterator entry = entries.GetFirstItem();
    int i = 0;
    while (entry) {
        PLT_DeviceDataReference device = (*entry)->GetValue();
        
        if (i == index) {
            m_CurMediaRenderer = device;
            break;
        }
        
        ++i;
        ++entry;
    }
    
    if (m_CurSelectIndex != -1) {
        openIndex(m_CurSelectIndex);
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_ls
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_ls()
{
    DoBrowse();

    if (!m_MostRecentBrowseResults.IsNull()) {
        printf("There were %d results\n", m_MostRecentBrowseResults->GetItemCount());

        NPT_List<PLT_MediaObject*>::Iterator item = m_MostRecentBrowseResults->GetFirstItem();
        while (item) {
            if ((*item)->IsContainer()) {
                printf("Container: %s (%s)\n", (*item)->m_Title.GetChars(), (*item)->m_ObjectID.GetChars());
            } else {
                printf("Item: %s (%s)\n", (*item)->m_Title.GetChars(), (*item)->m_ObjectID.GetChars());
            }
            ++item;
        }

        m_MostRecentBrowseResults = NULL;
    }
}


PLT_MediaObjectListReference
PLT_MicroMediaController::ls()
{
    DoBrowse();
    return m_MostRecentBrowseResults;
}

PLT_MediaObjectListReference
PLT_MicroMediaController::getCurBrowseResults()
{
    return m_MostRecentBrowseResults;
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_info
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_info()
{
    NPT_String              object_id;
    PLT_StringMap           tracks;
    PLT_DeviceDataReference device;

    // issue a browse
    DoBrowse();

    if (!m_MostRecentBrowseResults.IsNull()) {
        // create a map item id -> item title
        NPT_List<PLT_MediaObject*>::Iterator item = m_MostRecentBrowseResults->GetFirstItem();
        while (item) {
            if (!(*item)->IsContainer()) {
                tracks.Put((*item)->m_ObjectID, (*item)->m_Title);
            }
            ++item;
        }

        // let the user choose which one
        object_id = ChooseIDFromTable(tracks);

        if (object_id.GetLength()) {
            // issue a browse with metadata
            DoBrowse(object_id, true);

            // look back for the PLT_MediaItem in the results
            PLT_MediaObject* track = NULL;
            if (!m_MostRecentBrowseResults.IsNull() &&
                NPT_SUCCEEDED(NPT_ContainerFind(*m_MostRecentBrowseResults, PLT_MediaItemIDFinder(object_id), track))) {

                // display info
                printf("Title: %s \n", track->m_Title.GetChars());
                printf("OjbectID: %s\n", track->m_ObjectID.GetChars());
                printf("Class: %s\n", track->m_ObjectClass.type.GetChars());
                printf("Creator: %s\n", track->m_Creator.GetChars());
                printf("Date: %s\n", track->m_Date.GetChars());
                for (NPT_List<PLT_AlbumArtInfo>::Iterator iter = track->m_ExtraInfo.album_arts.GetFirstItem();
                     iter;
                     iter++) {
                    printf("Art Uri: %s\n", (*iter).uri.GetChars());
                    printf("Art Uri DLNA Profile: %s\n", (*iter).dlna_profile.GetChars());
                }
                for (NPT_Cardinal i=0;i<track->m_Resources.GetItemCount(); i++) {
                    printf("\tResource[%d].uri: %s\n", i, track->m_Resources[i].m_Uri.GetChars());
                    printf("\tResource[%d].profile: %s\n", i, track->m_Resources[i].m_ProtocolInfo.ToString().GetChars());
                    printf("\tResource[%d].duration: %d\n", i, track->m_Resources[i].m_Duration);
                    printf("\tResource[%d].size: %d\n", i, (int)track->m_Resources[i].m_Size);
                    printf("\n");
                }
                printf("Didl: %s\n", (const char*)track->m_Didl);
            } else {
                printf("Couldn't find the track\n");
            }
        }

        m_MostRecentBrowseResults = NULL;
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_download
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_download()
{
    NPT_String              object_id;
    PLT_StringMap           tracks;
    PLT_DeviceDataReference device;
    
    // issue a browse
    DoBrowse();
    
    if (!m_MostRecentBrowseResults.IsNull()) {
        // create a map item id -> item title
        NPT_List<PLT_MediaObject*>::Iterator item = m_MostRecentBrowseResults->GetFirstItem();
        while (item) {
            if (!(*item)->IsContainer()) {
                tracks.Put((*item)->m_ObjectID, (*item)->m_Title);
            }
            ++item;
        }
        
        // let the user choose which one
        object_id = ChooseIDFromTable(tracks);
        
        if (object_id.GetLength()) {
            // issue a browse with metadata
            DoBrowse(object_id, true);
            
            // look back for the PLT_MediaItem in the results
            PLT_MediaObject* track = NULL;
            if (!m_MostRecentBrowseResults.IsNull() &&
                NPT_SUCCEEDED(NPT_ContainerFind(*m_MostRecentBrowseResults, PLT_MediaItemIDFinder(object_id), track))) {
                
                if (track->m_Resources.GetItemCount() > 0) {
                    printf("\tResource[0].uri: %s\n", track->m_Resources[0].m_Uri.GetChars());
                    printf("\n");
                    NPT_HttpUrl url(track->m_Resources[0].m_Uri.GetChars());
                    if (url.IsValid()) {
                        // Extract filename from URL
                        NPT_String filename = NPT_FilePath::BaseName(url.GetPath(true).GetChars(), false);
                        NPT_String extension = NPT_FilePath::FileExtension(url.GetPath(true).GetChars());
                        printf("Downloading %s%s\n", filename.GetChars(), extension.GetChars());
                        
                        for (int i=0; i<3; i++) {
                            NPT_String filepath = NPT_String::Format("%s_%d%s", filename.GetChars(), i, extension.GetChars());
                            
                            // Open file for writing
                            NPT_File file(filepath);
                            file.Open(NPT_FILE_OPEN_MODE_WRITE | NPT_FILE_OPEN_MODE_CREATE | NPT_FILE_OPEN_MODE_TRUNCATE);
                            NPT_OutputStreamReference output;
                            file.GetOutputStream(output);
                            
                            // trigger 3 download
                            PLT_Downloader* downloader = new PLT_Downloader(url, output);
                            NPT_TimeInterval delay(5.);
                            m_DownloadTaskManager.StartTask(downloader, &delay);
                        }
                    }
                } else {
                    printf("No resources found");
                }
            } else {
                printf("Couldn't find the track\n");
            }
        }
        
        m_MostRecentBrowseResults = NULL;
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_cd
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_cd(const char* command)
{
    NPT_String    newobject_id;
    PLT_StringMap containers;

    // if command has parameter, push it to stack and return
    NPT_String id = command;
    NPT_List<NPT_String> args = id.Split(" ");
    if (args.GetItemCount() >= 2) {
        args.Erase(args.GetFirstItem());
        id = NPT_String::Join(args, " ");
        m_CurBrowseDirectoryStack.Push(id);
        return;
    }

    // list current directory to let user choose
    DoBrowse();

    if (!m_MostRecentBrowseResults.IsNull()) {
        NPT_List<PLT_MediaObject*>::Iterator item = m_MostRecentBrowseResults->GetFirstItem();
        while (item) {
            if ((*item)->IsContainer()) {
                containers.Put((*item)->m_ObjectID, (*item)->m_Title);
            }
            ++item;
        }

        newobject_id = ChooseIDFromTable(containers);
        if (newobject_id.GetLength()) {
            m_CurBrowseDirectoryStack.Push(newobject_id);
        }

        m_MostRecentBrowseResults = NULL;
    }
}


void
PLT_MicroMediaController::cd(NPT_String objID)
{
    m_CurBrowseDirectoryStack.Push(objID);
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_cdup
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_cdup()
{
    printf("HandleCmd_cdup.\n");
    // we don't want to pop the root off now....
    NPT_String val;
    m_CurBrowseDirectoryStack.Peek(val);
    if (val.Compare("0")) {
        m_CurBrowseDirectoryStack.Pop(val);
    } else {
        printf("Already at root\n");
    }
}


/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_pwd
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_pwd()
{
    NPT_Stack<NPT_String> tempStack;
    NPT_String val;

    while (NPT_SUCCEEDED(m_CurBrowseDirectoryStack.Peek(val))) {
        m_CurBrowseDirectoryStack.Pop(val);
        tempStack.Push(val);
    }

    while (NPT_SUCCEEDED(tempStack.Peek(val))) {
        tempStack.Pop(val);
        printf("%s/", (const char*)val);
        m_CurBrowseDirectoryStack.Push(val);
    }
    printf("\n");
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_open
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_open()
{
    NPT_String              object_id;
    PLT_StringMap           tracks;
    PLT_DeviceDataReference device;

    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        // get the protocol info to try to see in advance if a track would play on the device

        // issue a browse
        DoBrowse();

        if (!m_MostRecentBrowseResults.IsNull()) {
            // create a map item id -> item title
            NPT_List<PLT_MediaObject*>::Iterator item = m_MostRecentBrowseResults->GetFirstItem();
            while (item) {
                if (!(*item)->IsContainer()) {
                    tracks.Put((*item)->m_ObjectID, (*item)->m_Title);
                }
                ++item;
            }

            // let the user choose which one
            object_id = ChooseIDFromTable(tracks);
            if (object_id.GetLength()) {
                // look back for the PLT_MediaItem in the results
                PLT_MediaObject* track = NULL;
                if (NPT_SUCCEEDED(NPT_ContainerFind(*m_MostRecentBrowseResults, PLT_MediaItemIDFinder(object_id), track))) {
                    if (track->m_Resources.GetItemCount() > 0) {
                        // look for best resource to use by matching each resource to a sink advertised by renderer
                        NPT_Cardinal resource_index = 0;
                        if (NPT_FAILED(FindBestResource(device, *track, resource_index))) {
                            printf("No matching resource\n");
                            return;
                        }

                        // invoke the setUri
                        printf("Issuing SetAVTransportURI with url=%s & didl=%s", 
                            (const char*)track->m_Resources[resource_index].m_Uri, 
                            (const char*)track->m_Didl);
                        SetAVTransportURI(device, 0, track->m_Resources[resource_index].m_Uri, track->m_Didl, NULL);
                    } else {
                        printf("Couldn't find the proper resource\n");
                    }

                } else {
                    printf("Couldn't find the track\n");
                }
            }

            m_MostRecentBrowseResults = NULL;
        }
    }
}



bool PLT_MicroMediaController::openIndex(int index)
{
    PLT_DeviceDataReference device;
    
    GetCurMediaRenderer(device);
    
    m_CurSelectIndex = index;
    
    if (device.IsNull())
    {
        
        if (eventHandler) {
            eventHandler(event_media_selected,NULL, event_custom_data);
        }
        
    }
    else
    {
        // get the protocol info to try to see in advance if a track would play on the device
        if ( m_MostRecentBrowseResults.IsNull() == false && index >= m_MostRecentBrowseResults->GetItemCount()) {
            return false;
        }
        
        auto chooseOne = m_MostRecentBrowseResults->GetItem(index);
        
        PLT_MediaObject *t = *chooseOne;
        
        PLT_MediaObject* track = NULL;
        if (NPT_SUCCEEDED(NPT_ContainerFind(*m_MostRecentBrowseResults, PLT_MediaItemIDFinder(t->m_ObjectID), track)))
        {
            if (track->m_Resources.GetItemCount() > 0) {
                // look for best resource to use by matching each resource to a sink advertised by renderer
                NPT_Cardinal resource_index = 0;
                if (NPT_FAILED(FindBestResource(device, *track, resource_index))) {
                    printf("No matching resource\n");
                    return false;
                }
                
                /*
                // invoke the setUri
                printf("Issuing SetAVTransportURI with url=%s & didl=%s",
                       (const char*)track->m_Resources[resource_index].m_Uri,
                       (const char*)track->m_Didl);
                */
                
                m_CurBrowseIndex = index;
                
                mediaTitle = track->m_Title;
                
                SetAVTransportURI(device, 0, track->m_Resources[resource_index].m_Uri, track->m_Didl, NULL);
                
                return true;
                
            } else {
                printf("Couldn't find the proper resource\n");
            }
        }
        
    }
    
    return true;
}



NPT_String
PLT_MicroMediaController::playingMediaTitle()
{
    return mediaTitle;
}


void
PLT_MicroMediaController::clearPlayingMediaTitle()
{
    mediaTitle = NPT_String();
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_play
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_play()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        Play(device, 0, "1", NULL);
    }
}

/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::HandleCmd_pause
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_pause()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        Pause(device, 0, 0);
    }
}


/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_seek
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_seek(const char* command)
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        // remove first part of command ("seek")
        NPT_String target = command;
        NPT_List<NPT_String> args = target.Split(" ");
        if (args.GetItemCount() < 2) return;

        args.Erase(args.GetFirstItem());
        target = NPT_String::Join(args, " ");
        
        Seek(device, 0, (target.Find(":")!=-1)?"REL_TIME":"X_DLNA_REL_BYTE", target, NULL);
    }
}


/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_stop
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_stop()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        Stop(device, 0, NULL);
    }
}

/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::HandleCmd_next
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_next()
{
     PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        Next(device, 0, NULL);
    }   
}

/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::HandleCmd_prev
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_prev()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        Previous(device, 0, NULL);
    }
}

/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::HandleCmd_getVolumn
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_getVolumn()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        const char *channel = "Master";
        GetVolume(device, 0, channel , NULL);
    }
}

/*----------------------------------------------------------------------
 |   PLT_MicroMediaController::HandleCmd_setVolumn
 +---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_setVolumn(int volumn)
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        const char *channel = "Master";
        SetVolume(device, 0, channel, volumn, NULL);
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_getPositionInfo
+---------------------------------------------------------------------*/
void PLT_MicroMediaController::HandleCmd_getPositionInfo()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    
    GetPositionInfo(device, 0, NULL);
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_getMute
+---------------------------------------------------------------------*/
void PLT_MicroMediaController::HandleCmd_getMute()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
 
    GetMute(device, 0, "Master", NULL);
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_mute
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_mute()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        SetMute(device, 0, "Master", true, NULL);
    }
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_unmute
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_unmute()
{
    PLT_DeviceDataReference device;
    GetCurMediaRenderer(device);
    if (!device.IsNull()) {
        SetMute(device, 0, "Master", false, NULL);
    }
}



/*----------------------------------------------------------------------
|   PLT_MicroMediaController::HandleCmd_help
+---------------------------------------------------------------------*/
void
PLT_MicroMediaController::HandleCmd_help()
{
    printf("\n\nNone of the commands take arguments.  The commands with a * \n");
    printf("signify ones that will prompt the user for more information once\n");
    printf("the command is called\n\n");
    printf("The available commands are:\n\n");
    printf(" quit    -   shutdown the Control Point\n");
    printf(" exit    -   same as quit\n");

    printf(" setms   - * select a media server to become the active media server\n");
    printf(" getms   -   print the friendly name of the active media server\n");
    printf(" ls      -   list the contents of the current directory on the active \n");
    printf("             media server\n");
    printf(" info    -   display media info\n");
    printf(" down    -   download media to current directory\n");
    printf(" cd      - * traverse down one level in the content tree on the active\n");
    printf("             media server\n");
    printf(" cd ..   -   traverse up one level in the content tree on the active\n");
    printf("             media server\n");
    printf(" pwd     -   print the path from the root to your current position in the \n");
    printf("             content tree on the active media server\n");
    printf(" setmr   - * select a media renderer to become the active media renderer\n");
    printf(" getmr   -   print the friendly name of the active media renderer\n");
    printf(" open    -   set the uri on the active media renderer\n");
    printf(" play    -   play the active uri on the active media renderer\n");
    printf(" stop    -   stop the active uri on the active media renderer\n");
    printf(" seek    -   issue a seek command\n");
    printf(" mute    -   mute the active media renderer\n");
    printf(" unmute  -   unmute the active media renderer\n");

    printf(" help    -   print this help message\n\n");
}

/*----------------------------------------------------------------------
|   PLT_MicroMediaController::ProcessCommandLoop
+---------------------------------------------------------------------*/
void 
PLT_MicroMediaController::ProcessCommandLoop()
{
    char command[256];
    bool abort = false;

    while (!abort) {
//        printf("command> ");
        fflush(stdout);
        fgets(command, 2048, stdin);
        strchomp(command);

        if (0 == strcmp(command, "quit") || 0 == strcmp(command, "exit")) {
            abort = true;
        } else if (0 == strcmp(command, "setms")) {
            HandleCmd_setms();
        } else if (0 == strcmp(command, "getms")) {
            HandleCmd_getms();
        } else if (0 == strncmp(command, "ls", 2)) {
            HandleCmd_ls();
        } else if (0 == strcmp(command, "info")) {
            HandleCmd_info();
        } else if (0 == strcmp(command, "down")) {
            HandleCmd_download();
        } else if (0 == strcmp(command, "cd")) {
            HandleCmd_cd(command);
        } else if (0 == strcmp(command, "cd ..")) {
            HandleCmd_cdup();
        } else if (0 == strcmp(command, "pwd")) {
            HandleCmd_pwd();
        } else if (0 == strcmp(command, "setmr")) {
            HandleCmd_setmr();
        } else if (0 == strcmp(command, "getmr")) {
            HandleCmd_getmr();
        } else if (0 == strcmp(command, "open")) {
            HandleCmd_open();
        } else if (0 == strcmp(command, "play")) {
            HandleCmd_play();
        } else if (0 == strcmp(command, "stop")) {
            HandleCmd_stop();
        } else if (0 == strncmp(command, "seek", 4)) {
            HandleCmd_seek(command);
        } else if (0 == strcmp(command, "mute")) {
            HandleCmd_mute();
        } else if (0 == strcmp(command, "unmute")) {
            HandleCmd_mute();
        } else if (0 == strcmp(command, "help")) {
            HandleCmd_help();
        } else if (0 == strcmp(command, "")) {
            // just prompt again
        } else {
            printf("Unrecognized command: %s\n", command);
            HandleCmd_help();
        }
    }
}


/*----------------------------------------------------------------------
|   PLT_SyncMediaBrowser::BrowseSync
+---------------------------------------------------------------------*/
NPT_Result
PLT_SyncMediaBrowserMy::BrowseSync(PLT_DeviceDataReference&      device,
                                 const char*                   object_id, 
                                 PLT_MediaObjectListReference& list,
                                 bool                          metadata, /* = false */
                                 NPT_Int32                     start, /* = 0 */
                                 NPT_Cardinal                  max_results /* = 0 */)
{
    NPT_Result res = NPT_FAILURE;
    NPT_Int32  index = start;
    
    // only cache metadata or if starting from 0 and asking for maximum
    bool cache = m_UseCache && (metadata || (start == 0 && max_results == 0));

    // reset output params
    list = NULL;

    // look into cache first
    if (cache && NPT_SUCCEEDED(m_Cache.Get(device->GetUUID(), object_id, list))) return NPT_SUCCESS;

    do {	
        PLT_BrowseDataReference browse_data(new PLT_BrowseData());

        // send off the browse packet.  Note that this will
        // not block.  There is a call to WaitForResponse in order
        // to block until the response comes back.
        res = BrowseSync(
            browse_data,
            device,
            (const char*)object_id,
            index,
            metadata?1:30, // DLNA recommendations for browsing children is no more than 30 at a time
            metadata);
        
        NPT_CHECK_LABEL_WARNING(res, done);
        
        if (NPT_FAILED(browse_data->res)) {
            res = browse_data->res;
            NPT_CHECK_LABEL_WARNING(res, done);
        }

        // server returned no more, bail now
        if (browse_data->info.items->GetItemCount() == 0)
            break;

        if (list.IsNull()) {
            list = browse_data->info.items;
        } else {
            list->Add(*browse_data->info.items);
            // clear the list items so that the data inside is not
            // cleaned up by PLT_MediaItemList dtor since we copied
            // each pointer into the new list.
            browse_data->info.items->Clear();
        }

        // stop now if our list contains exactly what the server said it had.
        // Note that the server could return 0 if it didn't know how many items were
        // available. In this case we have to continue browsing until
        // nothing is returned back by the server.
        // Unless we were told to stop after reaching a certain amount to avoid
        // length delays
        // (some servers may return a total matches out of whack at some point too)
        if ((browse_data->info.tm && browse_data->info.tm <= list->GetItemCount()) ||
            (max_results && list->GetItemCount() >= max_results))
            break;

        // ask for the next chunk of entries
        index = list->GetItemCount();
    } while(1);

done:
    // cache the result
    if (cache && NPT_SUCCEEDED(res) && !list.IsNull() && list->GetItemCount()) {
        m_Cache.Put(device->GetUUID(), object_id, list);
    }

    // clear entire cache data for device if failed, the device could be gone
    if (NPT_FAILED(res) && cache) m_Cache.Clear(device->GetUUID());
    
    return res;
}

/*----------------------------------------------------------------------
|   PLT_SyncMediaBrowser::BrowseSync
+---------------------------------------------------------------------*/
NPT_Result 
PLT_SyncMediaBrowserMy::BrowseSync(PLT_BrowseDataReference& browse_data,
                                 PLT_DeviceDataReference& device, 
                                 const char*              object_id, 
                                 NPT_Int32                index, 
                                 NPT_Int32                count,
                                 bool                     browse_metadata,
                                 const char*              filter, 
                                 const char*              sort)
{
    NPT_Result res;

    browse_data->shared_var.SetValue(0);
    browse_data->info.si = index;

    // send off the browse packet.  Note that this will
    // not block.  There is a call to WaitForResponse in order
    // to block until the response comes back.
    res = PLT_MediaBrowser::Browse(device,
        (const char*)object_id,
        index,
        count,
        browse_metadata,
        filter,
        sort,
        new PLT_BrowseDataReference(browse_data));		
    NPT_CHECK_SEVERE(res);

    return WaitForResponse(browse_data->shared_var);
}


/*----------------------------------------------------------------------
|   PLT_SyncMediaBrowser::WaitForResponse
+---------------------------------------------------------------------*/
NPT_Result
PLT_SyncMediaBrowserMy::WaitForResponse(NPT_SharedVariable& shared_var)
{
    return shared_var.WaitUntilEquals(1, 30000);
}


const char *szObjectClassTypeImagePhoto= "object.item.imageItem.photo";
const char *szObjectClassTypeVideo= "object.item.videoItem";
const char *szObjectClassTypeAudioMusicTrack= "object.item.audioItem.musicTrack";
const char *szObjectClassTypeAudioBroadcast= "object.item.audioItem.audioBroadcast";

