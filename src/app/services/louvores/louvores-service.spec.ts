import { TestBed } from '@angular/core/testing';

import { LouvoresService } from './louvores-service';

describe('LouvoresService', () => {
  let service: LouvoresService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(LouvoresService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
