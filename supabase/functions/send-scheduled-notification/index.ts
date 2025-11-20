import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface NotificationRequest {
  userIds: string[]
  title: string
  message: string
  sendAfter: string // ISO string for when to send
  data?: Record<string, any>
}

serve(async (req: Request) => {
  try {
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID')!
    const oneSignalApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY')!
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    if (req.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 })
    }

    const { userIds, title, message, sendAfter, data }: NotificationRequest = await req.json()

    console.log(`Scheduling notification for ${userIds.length} users at ${sendAfter}`)

    // Get active devices for the users from user_devices table
    const { data: userDevices, error: devicesError } : { data: any[] | null, error: any } = await supabase
      .from('user_devices')
      .select('user_id, onesignal_user_id, device_id')
      .in('user_id', userIds)
      .eq('is_active', true)
      .not('onesignal_user_id', 'is', null)
      .neq('onesignal_user_id', '')

    if (devicesError) {
      console.error('Error fetching user devices:', devicesError)
      throw devicesError
    }

    // Fallback to using userIds directly if no devices are found
    // This is crucial if the device registration is delayed or fails
    const targetUserIds: string[] =
      userDevices && userDevices.length > 0
        ? userDevices.map((device: any) => device.user_id)
        : userIds

    if (targetUserIds.length === 0) {
      console.log('No valid target user IDs found')
      return new Response(
        JSON.stringify({ success: false, message: 'No valid target user IDs found' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`Found ${targetUserIds.length} active devices/users`)

    // Use include_external_user_ids with the actual user IDs from your system
    const oneSignalPayload = {
      app_id: oneSignalAppId,
      include_external_user_ids: targetUserIds,
      channel_for_external_user_ids: 'push',
      headings: { en: title },
      contents: { en: message },
      send_after: sendAfter,
      data: data || {},
      // REMOVED: android_channel_id - let OneSignal use default channel
      priority: 10,
      ttl: 86400, // 24 hours TTL for better offline delivery
      // Enhanced notification settings for better reliability and background handling
      android_sound: 'default',
      ios_sound: 'default',
      android_visibility: 1, // Public visibility
      // Delivery and retry strategies to improve reachability in varying conditions
      delayed_option: 'timezone',
      delivery_time_of_day: '9:00AM',
      // Allow background data for Android to help receive notifications when app is backgrounded
      android_background_data: true,
      // iOS badge handling
      ios_badgeType: 'Increase',
      ios_badgeCount: 1,
      // Add deep link URL if provided
      ...(data?.url && { url: data.url })
    }

    console.log('Sending scheduled notification to OneSignal:', JSON.stringify(oneSignalPayload, null, 2))

    const oneSignalResponse = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${oneSignalApiKey}`,
      },
      body: JSON.stringify(oneSignalPayload),
    })

    const oneSignalResult = await oneSignalResponse.json()

    if (!oneSignalResponse.ok) {
      console.error('OneSignal error:', oneSignalResult)
      throw new Error(`OneSignal API error: ${JSON.stringify(oneSignalResult)}`)
    }

    console.log('OneSignal response:', oneSignalResult)

    return new Response(
      JSON.stringify({
        success: true,
        message: `Scheduled notification for ${targetUserIds.length} users`,
        oneSignalId: oneSignalResult.id,
        scheduledFor: sendAfter,
        devicesTargeted: targetUserIds.length,
        oneSignalUserIds: targetUserIds,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in send-scheduled-notification:', error)
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})