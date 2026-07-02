import React from 'react';
import { PeopleEdge } from '../../types/people-links';

interface PeopleLinkEdgeProps {
  edge: PeopleEdge;
}

export const PeopleLinkEdge: React.FC<PeopleLinkEdgeProps> = ({ edge }) => {
  // Get source and target node names from IDs
  const sourceId = edge.sourceId;
  const targetId = edge.targetId;
  
  return (
    <div className="people-link-edge">
      <div className="edge-container">
        <div className="edge-source">
          <span className="node-id">{sourceId}</span>
        </div>
        
        <div className="edge-center">
          <div className="weight-indicator" style={{ width: `${Math.min(edge.weight * 10, 100)}px` }}>
            <span className="weight-value">w={edge.weight.toFixed(2)}</span>
          </div>
        </div>
        
        <div className="edge-target">
          <span className="node-id">{targetId}</span>
        </div>
      </div>
      
      {edge.contexts.length > 0 && (
        <div className="edge-contexts">
          <strong>Contexts:</strong>
          <ul>
            {edge.contexts.map(context => (
              <li key={context}>{context}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
};
