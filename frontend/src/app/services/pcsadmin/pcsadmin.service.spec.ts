import { TestBed } from '@angular/core/testing';

import { PcsadminService } from './pcsadmin.service';

describe('PcsadminService', () => {
  let service: PcsadminService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(PcsadminService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
