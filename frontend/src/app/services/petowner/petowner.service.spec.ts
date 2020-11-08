import { TestBed } from '@angular/core/testing';

import { PetownerService } from './petowner.service';

describe('PetownerService', () => {
  let service: PetownerService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(PetownerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
