import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async req => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    console.log('=== OneSignal Notification Function Started ===');

    // Create a Supabase client
    const supabaseClient = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_ANON_KEY') ?? '', {
      global: {
        headers: { Authorization: req.headers.get('Authorization') ?? '' },
      },
    });

    // Get the request body
    const { userIds, title, message, data } = await req.json();

    console.log('Request payload:', { userIds, title, message, data });

    // Validate required fields
    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new Error('userIds array is required and must not be empty');
    }
    if (!title || !message) {
      throw new Error('title and message are required');
    }

    // Get OneSignal configuration
    const oneSignalApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY');
    const oneSignalAppId = Deno.env.get('ONESIGNAL_APP_ID');

    if (!oneSignalApiKey || !oneSignalAppId) {
      throw new Error('OneSignal configuration missing: ONESIGNAL_REST_API_KEY or ONESIGNAL_APP_ID not set');
    }

    console.log('OneSignal App ID:', oneSignalAppId);
    console.log('Target user IDs:', userIds);

    // Since we're using OneSignal.login(userId), the external user IDs are the same as our user IDs
    // We don't need to query the database for OneSignal IDs - we can use the user IDs directly
    const oneSignalUserIds = userIds.filter(id => id && id.trim() !== '');

    console.log('OneSignal User IDs to target:', oneSignalUserIds);

    if (oneSignalUserIds.length === 0) {
      console.log('No users to target');
      return new Response(
        JSON.stringify({
          success: false,
          message: 'No users to target',
          targetUserIds: userIds,
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200,
        },
      );
    }

    // Prepare the notification payload for OneSignal
    const notification = {
      app_id: oneSignalAppId,
      headings: { en: title },
      contents: { en: message },
      include_external_user_ids: oneSignalUserIds, // This targets the external user IDs set with OneSignal.login
      data: data || {},
      // Optional: Add some default settings
      priority: 10, // High priority
    };

    console.log('OneSignal notification payload:', JSON.stringify(notification, null, 2));

    // Send the notification using OneSignal's REST API
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${oneSignalApiKey}`,
      },
      body: JSON.stringify(notification),
    });

    console.log('OneSignal API response status:', response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error('OneSignal API error:', errorText);
      throw new Error(`OneSignal API error: ${response.status} - ${errorText}`);
    }

    const result = await response.json();
    console.log('OneSignal API success response:', result);

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Notification sent successfully',
        targetUserIds: userIds,
        oneSignalUserIds: oneSignalUserIds,
        oneSignalResult: result,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      },
    );
  } catch (error) {
    console.error('Function error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString(),
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    );
  }
});
