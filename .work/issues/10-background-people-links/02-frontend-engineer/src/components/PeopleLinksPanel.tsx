import React, { useState, useEffect, useCallback } from 'react';
import { PeopleNode, PeopleEdge } from '../../types/people-links';

interface PeopleLinksPanelProps {
  nodes?: PeopleNode[];
  edges?: PeopleEdge[];
  isLoading?: boolean;
  error?: string | null;
  onRefresh?: () => void;
}

export const PeopleLinksPanel: React.FC<PeopleLinksPanelProps> = ({
  nodes = [],
  edges = [],
  isLoading = false,
  error = null,
  onRefresh
}) => {
  const [isGenerating, setIsGenerating] = useState(false);
  const [generationStatus, setGenerationStatus] = useState<string | null>(null);

  const triggerGeneration = useCallback(async () => {
    if (isGenerating) return;
    
    setIsGenerating(true);
    setGenerationStatus('Generating people links...');
    
    try {
      const response = await fetch('/api/people-links/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      if (!response.ok) {
        throw new Error(`Generation failed: ${response.statusText}`);
      }
      
      const { taskId } = await response.json();
      setGenerationStatus(`Generation started (Task: ${taskId})`);
      
      // Poll for status
      const pollStatus = async () => {
        try {
          const statusResponse = await fetch(`/api/people-links/status/${taskId}`);
          const status = await statusResponse.json();
          
          if (status.status === 'completed') {
            setGenerationStatus('Generation completed!');
            setIsGenerating(false);
            onRefresh?.();
          } else if (status.status === 'failed') {
            setGenerationStatus(`Generation failed: ${status.error}`);
            setIsGenerating(false);
          } else if (status.status === 'running') {
            setGenerationStatus(`Generating... ${status.progress}%`);
            setTimeout(pollStatus, 1000);
          }
        } catch (err) {
          setGenerationStatus('Failed to check generation status');
          setIsGenerating(false);
        }
      };
      
      pollStatus();
      
    } catch (err) {
      setGenerationStatus(`Error: ${(err as Error).message}`);
      setIsGenerating(false);
    }
  }, [isGenerating, onRefresh]);

  return (
    <div className="people-links-panel">
      <div className="panel-header">
        <h2>People Links</h2>
        <button 
          onClick={triggerGeneration}
          disabled={isGenerating || isLoading}
          className="generate-btn"
        >
          {isGenerating ? 'Generating...' : 'Regenerate Links'}
        </button>
      </div>

      {isLoading && (
        <div className="loading-state">
          <span>Loading people links...</span>
        </div>
      )}

      {error && (
        <div className="error-state">
          <span>Error: {error}</span>
        </div>
      )}

      {generationStatus && (
        <div className="generation-status">
          <span>{generationStatus}</span>
        </div>
      )}

      {!isLoading && !error && nodes.length === 0 && (
        <div className="empty-state">
          <span>No people links available.</span>
          <button onClick={triggerGeneration} disabled={isGenerating}>
            Generate Links
          </button>
        </div>
      )}

      {nodes.length > 0 && (
        <div className="links-container">
          <div className="nodes-section">
            <h3>People ({nodes.length})</h3>
            {nodes.map(node => (
              <PeopleLinkNode key={node.id} node={node} />
            ))}
          </div>

          <div className="edges-section">
            <h3>Connections ({edges.length})</h3>
            {edges.map((edge, index) => (
              <PeopleLinkEdge key={index} edge={edge} />
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
