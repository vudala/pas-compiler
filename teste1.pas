program exemplo75 (input, output);
var m,n:  integer;
    v, p: boolean;
begin
    m := 3;
    n := 39 + m;

    if(m = 2) then
    begin
        m := 1;

        if(n = 42) then
        begin
            m := 32;
        end
        else
        begin
            m := 37;
        end;
    end
    else
    begin
        m := 2;
    end;
end.