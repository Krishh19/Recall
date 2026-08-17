import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.48.1';
import { corsHeaders } from '../_shared/cors.ts';
import { extractContent } from '../_shared/extractors.ts';

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') || Deno.env.get('GOOGLE_API_KEY');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_ANON_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const AI_SYSTEM_PROMPT = `You are the content intelligence engine for Recall, a reading and bookmarking app.
Analyze the provided content and return a JSON object adhering STRICTLY to this format:
{
  "summary": "1-2 plain-language sentences summarizing the core idea",
  "key_points": ["point 1", "point 2", "point 3"],
  "category": "one of: Technology, Business, Health, Education, Entertainment, News, Food, Finance, Other",
  "tags": ["3-6 lowercase keywords"],
  "estimated_read_time_minutes": 2
}
Do NOT include any markdown code fences or other text outside the JSON object.`;

interface AIResponse {
  summary: string;
  key_points: string[];
  category: string;
  tags: string[];
  estimated_read_time_minutes?: number;
}

/**
 * Calls Google Gemini REST API to summarize and classify the extracted content.
 */
async function generateSummaryWithGemini(
  title: string,
  content: string
): Promise<AIResponse> {
  if (!GEMINI_API_KEY) {
    throw new Error('GEMINI_API_KEY environment variable is not configured.');
  }

  // Cap content at 6000 characters
  const trimmedContent = content.slice(0, 6000);
  const promptText = `Title: ${title}\n\nContent:\n${trimmedContent}`;

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`;

  const payload = {
    system_instruction: {
      parts: [{ text: AI_SYSTEM_PROMPT }],
    },
    contents: [
      {
        parts: [{ text: promptText }],
      },
    ],
    generationConfig: {
      responseMimeType: 'application/json',
      temperature: 0.2,
    },
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`Gemini API error (${response.status}): ${errorBody}`);
  }

  const data = await response.json();
  const rawJsonText =
    data.candidates?.[0]?.content?.parts?.[0]?.text || '{}';

  return JSON.parse(rawJsonText) as AIResponse;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  let itemId = '';
  let url = '';

  try {
    const body = await req.json();

    // Support both direct invocation and Supabase database webhook payloads
    if (body.record) {
      itemId = body.record.id;
      url = body.record.url;
    } else {
      itemId = body.id;
      url = body.url;
    }

    if (!itemId || !url) {
      return new Response(
        JSON.stringify({ error: 'Missing required parameters: id and url.' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // 1. Content Extraction
    console.log(`Processing item ${itemId}: Extracting content from ${url}...`);
    const extracted = await extractContent(url);

    // 2. AI Summarization with Gemini
    console.log(`Summarizing item ${itemId} with Gemini...`);
    const aiResult = await generateSummaryWithGemini(
      extracted.title,
      extracted.raw_content
    );

    // 3. Update saved_items database row
    const { error: updateError } = await supabase
      .from('saved_items')
      .update({
        title: extracted.title,
        thumbnail_url: extracted.thumbnail_url,
        raw_content: extracted.raw_content,
        summary: aiResult.summary,
        key_points: aiResult.key_points,
        category: aiResult.category,
        tags: aiResult.tags,
        status: 'done',
      })
      .eq('id', itemId);

    if (updateError) {
      throw new Error(`Database update failed: ${updateError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        item_id: itemId,
        status: 'done',
        title: extracted.title,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (err: unknown) {
    const errorMessage = err instanceof Error ? err.message : String(err);
    console.error(`Processing error for item ${itemId}:`, errorMessage);

    if (itemId) {
      await supabase
        .from('saved_items')
        .update({
          status: 'failed',
          summary: `Processing error: ${errorMessage}`,
        })
        .eq('id', itemId);
    }

    return new Response(
      JSON.stringify({
        success: false,
        item_id: itemId,
        status: 'failed',
        error: errorMessage,
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
