/**
 * Primarch JavaScript SDK - Comprehensive Example
 */

const { PrimarchClient, PrimarchError, PrimarchAPIError } = require('@primarch/sdk');

class PrimarchExample {
  constructor() {
    // Initialize client
    this.client = new PrimarchClient({
      apiKey: process.env.PRIMARCH_API_KEY,
      baseURL: 'https://api.primarch.ai/v1',
      timeout: 30000,
      maxRetries: 3,
      retryDelay: 1000
    });
  }

  async basicCompletion() {
    console.log('=== Basic Completion ===');

    try {
      const response = await this.client.completions.create({
        prompt: 'Explain the importance of AI safety in 3 paragraphs',
        model: 'llama-3.1-8b-instruct',
        maxTokens: 500,
        temperature: 0.7,
        persona: 'frank'
      });

      console.log('Response:', response.choices[0].message.content);
      console.log(`Usage: ${response.usage.totalTokens} tokens`);
      return response;

    } catch (error) {
      if (error instanceof PrimarchAPIError) {
        console.error(`API Error: ${error.message} (Code: ${error.code})`);
      } else {
        console.error('Unexpected error:', error);
      }
      throw error;
    }
  }

  async streamingCompletion() {
    console.log('\n=== Streaming Completion ===');

    try {
      const stream = await this.client.completions.createStream({
        prompt: 'Write a story about a helpful AI assistant',
        model: 'llama-3.1-8b-instruct',
        maxTokens: 800,
        temperature: 0.8
      });

      console.log('Streaming response:');

      for await (const chunk of stream) {
        if (chunk.delta?.content) {
          process.stdout.write(chunk.delta.content);
        }
      }
      console.log('\n');

    } catch (error) {
      console.error('Streaming error:', error);
      throw error;
    }
  }

  async embeddingsExample() {
    console.log('\n=== Embeddings ===');

    const texts = [
      'Artificial intelligence is transforming technology',
      'Machine learning models require careful training',
      'AI safety is crucial for responsible deployment'
    ];

    try {
      const response = await this.client.embeddings.create({
        input: texts,
        model: 'text-embedding-3-small'
      });

      console.log(`Generated ${response.data.length} embeddings`);
      response.data.forEach((embedding, i) => {
        console.log(`Text ${i + 1}: ${embedding.embedding.length} dimensions`);
      });

      return response;

    } catch (error) {
      console.error('Embeddings error:', error);
      throw error;
    }
  }

  async batchProcessing() {
    console.log('\n=== Batch Processing ===');

    try {
      const prompts = [
        'Explain quantum computing',
        'Describe machine learning',
        'What is artificial intelligence?',
        'Define neural networks',
        'Explain deep learning'
      ];

      console.log('Processing batch of prompts...');

      // Process in parallel with concurrency limit
      const batchSize = 3;
      const results = [];

      for (let i = 0; i < prompts.length; i += batchSize) {
        const batch = prompts.slice(i, i + batchSize);

        const batchPromises = batch.map(async (prompt, index) => {
          const response = await this.client.completions.create({
            prompt,
            model: 'llama-3.1-8b-instruct',
            maxTokens: 150
          });

          return {
            index: i + index,
            prompt,
            response: response.choices[0].message.content,
            tokens: response.usage.totalTokens
          };
        });

        const batchResults = await Promise.all(batchPromises);
        results.push(...batchResults);

        console.log(`Completed batch ${Math.floor(i / batchSize) + 1}`);
      }

      console.log('\nBatch Results:');
      results.forEach(result => {
        console.log(`${result.index + 1}. ${result.prompt}`);
        console.log(`   Response: ${result.response.substring(0, 100)}...`);
        console.log(`   Tokens: ${result.tokens}`);
      });

    } catch (error) {
      console.error('Batch processing error:', error);
      throw error;
    }
  }
}

// Export for module usage
module.exports = { PrimarchExample };

// Main execution function
async function main() {
  console.log('=== PRIMARCH JAVASCRIPT SDK EXAMPLES ===');

  const example = new PrimarchExample();

  try {
    await example.basicCompletion();
    await example.streamingCompletion();
    await example.embeddingsExample();
    await example.batchProcessing();

    console.log('\n=== ALL EXAMPLES COMPLETED ===');

  } catch (error) {
    console.error('Example execution failed:', error);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main().catch(console.error);
}
