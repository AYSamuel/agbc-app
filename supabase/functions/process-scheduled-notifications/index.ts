import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req: Request) => {
  try {
    // 1. Initialize Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID')!
    const oneSignalApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 2. Fetch "Due" Notifications
    //    - scheduled_for is in the past (or now)
    //    - is_push_sent is false
    //    - Limit to 50 to avoid timeouts (cron runs every 1/10 mins, so this should drain queue)
    const { data: notifications, error: fetchError } = await supabase
      .from('notifications')
      .select('id, user_id, title, message, data, scheduled_for')
      .eq('is_push_sent', false)
      .lte('scheduled_for', new Date().toISOString())
      .limit(50)

    if (fetchError) {
      console.error('Error fetching notifications:', fetchError)
      throw fetchError
    }

    if (!notifications || notifications.length === 0) {
      console.log('No pending notifications to process')
      return new Response(JSON.stringify({ message: 'No pending notifications' }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log(`Found ${notifications.length} notifications to process`)

    // 3. Process each notification
    //    For efficiency, we could batch by user, but since messages might differ, 
    //    we'll process them individually or grouped by exact message/title matching.
    //    For now, individual processing to ensure customized data is preserved.
    
    // Config for OneSignal
    const results = []

    for (const notification of notifications) {
      try {
        // A. Determine Target (Broadcast or User)
        let targetIds: string[] = []
        let filters: any[] = [] // OneSignal filters (segments/tags)

        if (notification.user_id) {
            // Personal Notification
            const { data: devices } = await supabase
              .from('user_devices')
              .select('onesignal_user_id')
              .eq('user_id', notification.user_id)
              .eq('is_active', true)
              .neq('onesignal_user_id', null)
            
            if (devices && devices.length > 0) {
                targetIds = devices.map((d: any) => d.onesignal_user_id)
            } else {
                targetIds = [notification.user_id]
            }
        } else if (notification.target_type === 'branch') {
            // Broadcast to Branch (Using Tags)
            // Assuming users are tagged with "branch_id" : "some_uuid" in OneSignal
            filters = [
                { field: "tag", key: "branch_id", relation: "=", value: notification.target_value }
            ]
        } else if (notification.target_type === 'global') {
            // Broadcast to All (Subscribed Users)
            filters = [
                { field: "tag", key: "role", relation: "exists" } // Or just "all" segment? OneSignal "included_segments": ["Subscribed Users"]
            ]
        }

        // B. Send to OneSignal
        const oneSignalPayload: any = {
          app_id: oneSignalAppId,
          headings: { en: notification.title },
          contents: { en: notification.message },
          data: notification.data || {},
          android_channel_id: 'default',
          priority: 10,
          ttl: 86400,
        }

        if (targetIds.length > 0) {
            oneSignalPayload.include_external_user_ids = targetIds
            oneSignalPayload.channel_for_external_user_ids = 'push'
        } else if (filters.length > 0) {
             oneSignalPayload.filters = filters
        } else if (notification.target_type === 'global') {
             oneSignalPayload.included_segments = ["Subscribed Users"]
        } else {
            // No valid target
            console.warn(`Skipping notification ${notification.id} - no target`)
            // Mark as failed/skipped
             await supabase.from('notifications').update({ is_push_sent: true, delivery_status: 'skipped' }).eq('id', notification.id)
             continue
        }

        // B. Send to OneSignal
        const oneSignalPayload = {
          app_id: oneSignalAppId,
          include_external_user_ids: targetIds,
          channel_for_external_user_ids: 'push',
          headings: { en: notification.title },
          contents: { en: notification.message },
          data: notification.data || {},
          // Standard settings
          android_channel_id: 'default',
          priority: 10,
          ttl: 86400, // 24h
        }

        const osResponse = await fetch('https://onesignal.com/api/v1/notifications', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Basic ${oneSignalApiKey}`,
          },
          body: JSON.stringify(oneSignalPayload),
        })
        
        const osResult = await osResponse.json()

        // C. Update Database Record
        //    Mark as sent regardless of OneSignal 200/400 to prevent loop (unless 500?)
        //    But best to mark as sent if we attempted it.
        await supabase
          .from('notifications')
          .update({
            is_push_sent: true,
            delivery_status: osResponse.ok ? 'sent' : 'failed',
            sent_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('id', notification.id)

        results.push({ 
            id: notification.id, 
            success: osResponse.ok, 
            osResult 
        })

      } catch (innerError) {
        console.error(`Error processing notification ${notification.id}:`, innerError)
        results.push({ id: notification.id, success: false, error: innerError })
      }
    }

    return new Response(
      JSON.stringify({
        message: `Processed ${notifications.length} notifications`,
        results,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in process-scheduled-notifications:', error)
    return new Response(
      JSON.stringify({ error: String(error) }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
