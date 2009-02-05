/*
 * Copyright (C) 2009 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2009 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

using Rygel;
using GUPnP;
using Gee;
using Gst;

[ModuleInit]
public Plugin load_plugin () {
    Plugin plugin = new Plugin ("Test");

    // We only implement a ContentDirectory service
    var resource_info = new ResourceInfo (ContentDirectory.UPNP_ID,
                                          ContentDirectory.UPNP_TYPE,
                                          ContentDirectory.DESCRIPTION_PATH,
                                          typeof (TestContentDir));

    plugin.add_resource (resource_info);

    return plugin;
}

/**
 * Implementation of ContentDirectory service, meant for testing purposes only.
 */
public class Rygel.TestContentDir : ContentDirectory {

    public override MediaContainer? create_root_container () {
        return new TestRootContainer ();
    }
}

/**
 * Represents the root container for Test media content hierarchy.
 */
public class Rygel.TestRootContainer : MediaContainer {

    private ArrayList<MediaItem> items;

    public TestRootContainer () {
        base.root ("Test Title", 0);

        this.items = new ArrayList<MediaItem> ();
        this.items.add (new TestItem ("sinewave",      // ID
                                      this.id,         // ParentID
                                      "Sine Wave"));   // Title

        // Now we know how many top-level items we have
        this.child_count = this.items.size;
    }

    public override Gee.List<MediaObject>? get_children (uint offset,
                                                         uint max_count)
                                                         throws GLib.Error {
        uint stop = offset + max_count;

        stop = stop.clamp (0, this.child_count);
        return this.items.slice ((int) offset, (int) stop);
    }

    public override MediaObject? find_object (string id) throws GLib.Error {
        MediaItem item = null;

        foreach (MediaItem tmp in this.items) {
            if (id == tmp.id) {
                item = tmp;

                break;
            }
        }

        return item;
    }
}

/**
 * Represents Test audio item.
 */
public class Rygel.TestItem : Rygel.MediaItem {

    const string TEST_ID = "sine-wave";
    const string TEST_TITLE = "Sine Wave";
    const string TEST_AUTHOR = "Zeeshan Ali (Khattak)";
    const string TEST_MIMETYPE = "audio/x-wav";

    public TestItem (string parent_id) {
        base (TEST_ID, parent_id, TEST_TITLE, MediaItem.AUDIO_CLASS);

        this.mime_type = TEST_MIMETYPE;
        this.author = TEST_AUTHOR;
    }

    public override Element? create_stream_source () {
        Bin bin = new Bin (this.title);

        dynamic Element src = ElementFactory.make ("audiotestsrc", null);
        Element encoder = ElementFactory.make ("wavenc", null);

        if (src == null || encoder == null) {
            warning ("Required plugin missing");

            return null;
        }

        // Tell the source to behave like a live source
        src.is_live = true;

        // Add elements to our source bin
        bin.add_many (src, encoder);
        // Link them
        src.link (encoder);

        // Now add the encoder's src pad to the bin
        Pad pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (bin.name + "." + pad.name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}

