import {
  determineRatingPrefix,
  getClassificationState
} from '../srv/features/classification-feature';
import { Classification } from '#cds-models/kernseife/db';
import { describe, expect, it } from '@jest/globals';

describe('ClassificationFeature', () => {
  describe('determineRatingPrefix', () => {
    it('should return EF prefix for ENHS subType', () => {
      const classification = { subType: 'ENHS' } as Classification;
      expect(determineRatingPrefix(classification, '0')).toBe('EF0');
    });

    it('should return FW prefix for BC applicationComponent', () => {
      const classification = { applicationComponent: 'BC' } as Classification;
      expect(determineRatingPrefix(classification, '1')).toBe('FW1');
    });

    it('should return FW prefix for BC-* applicationComponent', () => {
      const classification = {
        applicationComponent: 'BC-MM'
      } as Classification;
      expect(determineRatingPrefix(classification, '5')).toBe('FW5');
    });

    it('should return FW prefix for CA applicationComponent', () => {
      const classification = { applicationComponent: 'CA' } as Classification;
      expect(determineRatingPrefix(classification, '9')).toBe('FW9');
    });

    it('should return FW prefix for SAP_BASIS softwareComponent', () => {
      const classification = {
        softwareComponent: 'SAP_BASIS'
      } as Classification;
      expect(determineRatingPrefix(classification, '0')).toBe('FW0');
    });

    it('should return BF prefix for business function', () => {
      const classification = {
        applicationComponent: 'MM',
        softwareComponent: 'CUSTOM'
      } as Classification;
      expect(determineRatingPrefix(classification, '3')).toBe('BF3');
    });
  });

  describe('getClassificationState', () => {
    it('should return classicAPI for CLASSIC release level', () => {
      const classification = { releaseLevel_code: 'CLASSIC' } as Classification;
      expect(getClassificationState(classification)).toBe('classicAPI');
    });

    it('should return noAPI for NO_API release level', () => {
      const classification = { releaseLevel_code: 'NO_API' } as Classification;
      expect(getClassificationState(classification)).toBe('noAPI');
    });

    it('should return internalAPI for other release levels', () => {
      const classification = {
        releaseLevel_code: 'undefined'
      } as Classification;
      expect(getClassificationState(classification)).toBe('internalAPI');
    });
  });
});
